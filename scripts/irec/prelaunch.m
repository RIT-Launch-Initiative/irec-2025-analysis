%% PRE‑LAUNCH DAY ROCKET NOSE MASS OPTIMIZATION (uses cached airdata)
% to create a cache of air data use create_airdata_files.m
% if the cahce does not exsist, this script will download the weather data
% for the nominal window

clear; close all; clc;

% --------------------------------------------------------------------
rocket_file = "rocket_files\IREC_2025_M6000ST-0.ork";
sim_name    = "10MPH-TEXAS-36C-(TYP)";
site_name   = "spaceport-midland";
nose_cmp_name = 'Adjustable stability weight(s)';

ref_time = datetime('now','TimeZone','-05:00') - hours(12);
nominal_launch_time = datetime(2025,06,11,12,0,0,'TimeZone','-05:00');
time_window_hours   = 5;                       % ± range
time_step_hours     = 1;                        % resolution

target_apogee_ft = 10775;
mass_min_kg      = 0.0;
mass_max_kg      = 2.5;
tolerance_ft     = 10;
pucks_g          = [1645 795 390 195 95 45];

cache_dir = fullfile(pwd,'scripts\irec\airdata_cache\wed');   % same folder used by creator script
% --------------------------------------------------------------------

launch_window = nominal_launch_time + ...
                hours(-time_window_hours:time_step_hours:time_window_hours);
fprintf("Analyzing %d time slots\n",numel(launch_window));

otis = openrocket(rocket_file);
sim  = otis.sims(sim_name);
site = launchsites(site_name);
nose_component = otis.component('name',nose_cmp_name);
ft2m = 0.3048;

num_sims = numel(launch_window);
optimal_masses_kg = nan(1,num_sims);
data_launchtemps  = nan(1,num_sims);
data_launchwinds  = nan(1,num_sims);
data_apogees      = nan(1,num_sims);
data_wind_dir = nan(1,num_sims);

wbar = waitbar(0,"Starting simulations…");

for i = 1:num_sims
    t = launch_window(i);
    waitbar((i-1)/num_sims,wbar,"Loading atmosphere…");

    % ----- load cached .mat (fallback to live fetch if missing) --------------
    matfile = fullfile(cache_dir, sprintf('airdata_%s.mat',datestr(t,'yyyymmdd_HHMM')));
    if exist(matfile,'file')
        S = load(matfile,'airdata');
        airdata = S.airdata;
    else
        warning("Cache miss – fetching live for %s",string(t));
        airdata = atmosphere("nam","awphys",site.lat,site.lon,t, ...
                             minpres=450,cache=matfile,reftime=ref_time);
    end
    % -------------------------------------------------------------------------

    airdata.TMP = airdata.TMP + 273.15;   % to Kelvin

    launch_temp_K = interp1(airdata.HGT,airdata.TMP,site.alt,'linear','extrap');
    u = interp1(airdata.HGT,airdata.UGRD,site.alt,'linear','extrap');
    v = interp1(airdata.HGT,airdata.VGRD,site.alt,'linear','extrap');
    wind_speed_ms = hypot(v,u);

    fprintf(' %s  %.1f °C  %.1f m/s  ',datestr(t),launch_temp_K-273.15,wind_speed_ms);
    

    [req_mass_kg,apogee_ft] = nm_getmass(launch_temp_K,wind_speed_ms, ...
        otis,sim,nose_component,target_apogee_ft,mass_min_kg,mass_max_kg, ...
        tolerance_ft,ft2m,airdata);

    optimal_masses_kg(i) = req_mass_kg;
    data_launchtemps(i)  = launch_temp_K-273.15;
    data_launchwinds(i)  = wind_speed_ms;
    data_apogees(i)      = apogee_ft;
    data_wind_dir(i) = rad2deg(unwrap(atan2(u,v)));




    if ~isnan(req_mass_kg)
        fprintf("mass %.3f kg\n",req_mass_kg);
    else
        fprintf("failed\n");
    end
    waitbar(i/num_sims,wbar);
end
close(wbar);

% ---- PICK NOSE‑MASS THAT MINIMISES RMS APOGEE ERROR (not simple mean) ----
errFun = @(m) rms( arrayfun(@(k) ...
          nm_apog_at_mass(m,launch_window(k),otis,sim,nose_component, ...
                          cache_dir,site,ref_time,ft2m,target_apogee_ft), ...
          1:num_sims) , 'omitnan');

best_mass_kg = fminbnd(errFun,mass_min_kg,mass_max_kg);
avg_mass_kg  = best_mass_kg;   % keep the old name so the rest of the script works

std_dev_kg  = std(optimal_masses_kg,'omitnan');
[puck_combo_g,residual_g] = split_into_pucks(avg_mass_kg,pucks_g);

fprintf('\n--- LAUNCH‑DAY RECOMMENDATION ---\n');
fprintf('Avg nose mass: %.3f kg  (%.0f g)\n',avg_mass_kg,avg_mass_kg*1000);
fprintf('Std dev:       %.3f kg  (%.0f g)\n',std_dev_kg,std_dev_kg*1000);
fprintf('Pucks:         %s g  (sum %.0f g, residual %.0f g)\n', ...
        mat2str(puck_combo_g),sum(puck_combo_g),residual_g);

figure;
tlo = tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

% 1) Optimal Nose Mass
nexttile(tlo,1)
plot(launch_window, optimal_masses_kg*1000, '-o','LineWidth',1.5)
grid on; datetick('x','keeplimits')
xlabel('Launch Time')
ylabel('Nose Mass (g)')
title('Optimal Nose Mass')


% 2) Wind Speed
nexttile(tlo,2)
plot(launch_window, data_launchwinds, '-s','LineWidth',1.5)
grid on; datetick('x','keeplimits')
xlabel('Launch Time')
ylabel('Wind Speed (m/s)')
title('Wind Speed')

% 3) Wind Direction
nexttile(tlo,3)
plot(launch_window, data_wind_dir, '-^','LineWidth',1.5)
grid on; datetick('x','keeplimits')
xlabel('Launch Time')
ylabel('Wind Dir. (°)')
title('Wind Direction')

% 4) Launch Temperature
nexttile(tlo,4)
plot(launch_window, data_launchtemps, '-d','LineWidth',1.5)
grid on; datetick('x','keeplimits')
xlabel('Launch Time')
ylabel('Temp. (°C)')
title('Launch Temperature')

%% Re-run sims at average nose mass and plot apogee vs. time
% Use the previously computed avg_mass_kg and launch_window

% Preallocate
fixed_apogees = nan(size(launch_window));

wbar2 = waitbar(0,"Re-running sims at avg mass…");
for i = 1:num_sims
    t = launch_window(i);
    
    % load cached atmosphere
    matfile = fullfile(cache_dir, sprintf('airdata_%s.mat',datestr(t,'yyyymmdd_HHMM')));
    if exist(matfile,'file')
        S = load(matfile,'airdata');
        airdata = S.airdata;
    else
        airdata = atmosphere("gfs","pgrb2.0p25",site.lat,site.lon,t, ...
                             minpres=450,cache=matfile,reftime=ref_time);
    end
    airdata.TMP = airdata.TMP + 273.15;
    
    % simulate with avg mass
    nose_component.setOverrideMass(avg_mass_kg);
    nose_component.setComponentMass(avg_mass_kg);
    data = otis.simulate(sim,'outputs','Altitude', ...
                         atmos=airdata(:,["HGT","PRES","TMP","UGRD","VGRD"]));
    fixed_apogees(i) = max(data.Altitude)/ft2m;
    
    waitbar(i/num_sims,wbar2,sprintf("Sim %d/%d at %.3f kg",i,num_sims,avg_mass_kg));
end
close(wbar2);

% % Plot
% nexttile(tlo,[2 1]) % spans 2 rows, 1 column
% plot(launch_window, abs(fixed_apogees-10700), '-o','LineWidth',1.5);
% grid on; datetick('x','keeplimits');
% xlabel('Launch Time');
% ylabel('Apogee Error (ft)');
% ytickformat('%0.0f')
% title(sprintf('Apogee Error vs. Time @ %.3f kg Nose Mass', avg_mass_kg));
% xtickangle(45);


% ====== helper functions (unchanged from original) ===========================
function [reqMass_kg,apogee_ft] = nm_getmass(Tlaunch_K,wind_speed_ms, ...
                    otis,simObj,cmp,target_ft,lo_kg,hi_kg,tol_ft,ft2m,airdata)
    costFun = make_cost_function(otis,simObj,cmp,wind_speed_ms,Tlaunch_K, ...
                                 target_ft,ft2m,lo_kg,hi_kg,airdata);
    opts    = optimset('Display','none','TolFun',tol_ft,'TolX',0.002);
    m0      = 0.5*(lo_kg+hi_kg);
    [reqMass_kg,fval,exitflag] = fminsearch(costFun,m0,opts);

    if exitflag<=0 || fval>tol_ft || reqMass_kg<lo_kg || reqMass_kg>hi_kg
        reqMass_kg = NaN; apogee_ft = NaN; return
    end
    cmp.setOverrideMass(reqMass_kg); cmp.setComponentMass(reqMass_kg);
    data      = otis.simulate(simObj,'outputs','Altitude', ...
                 atmos=airdata(:,["HGT","PRES","TMP","UGRD","VGRD"]));
    apogee_ft = max(data.Altitude)/ft2m;
end

function func = make_cost_function(otis,simObj,cmp,W_ms,Tlaunch_K, ...
                                   target_ft,ft2m,lo_kg,hi_kg,airdata)
    opts = simObj.getOptions();
    opts.setWindSpeedAverage(W_ms);
    opts.setWindSpeedDeviation(0);
    opts.setLaunchIntoWind(false);
    opts.setTimeStep(0.05);
    opts.setLaunchTemperature(Tlaunch_K);

    func = @cost;
    function err = cost(m)
        m = min(max(m(1),lo_kg),hi_kg);
        cmp.setOverrideMass(m); cmp.setComponentMass(m);
        data  = otis.simulate(simObj,'outputs','Altitude', ...
                atmos=airdata(:,["HGT","PRES","TMP","UGRD","VGRD"]));
        apog  = max(data.Altitude)/ft2m;
        err   = abs(apog - target_ft);
    end
end

function [combo,res] = split_into_pucks(req_kg,pucks_g)
    remaining_g = round(req_kg*1000);
    combo = [];
    for p = pucks_g
        if remaining_g >= p
            combo(end+1) = p; %#ok<AGROW>
            remaining_g  = remaining_g - p;
        end
    end
    res = remaining_g;
end

function err_ft = nm_apog_at_mass(mass_kg,t,otis,simObj,cmp, ...
                                  cache_dir,site,ref_time,ft2m,target_ft)
    % load cached air‑data (falls back to live fetch if needed)
    matfile = fullfile(cache_dir,sprintf('airdata_%s.mat',datestr(t,'yyyymmdd_HHMM')));
    if exist(matfile,'file')
        S = load(matfile,'airdata'); airdata = S.airdata;
    else
        airdata = atmosphere("nam","awphys",site.lat,site.lon,t, ...
                             minpres=450,cache=matfile,reftime=ref_time);
    end
    airdata.TMP = airdata.TMP + 273.15;

    % run sim at this mass
    cmp.setOverrideMass(mass_kg); cmp.setComponentMass(mass_kg);
    data     = otis.simulate(simObj,'outputs','Altitude', ...
                 atmos=airdata(:,["HGT","PRES","TMP","UGRD","VGRD"]));
    apog_ft  = max(data.Altitude)/ft2m;
    err_ft   = apog_ft - target_ft;      % signed error (will be rms’ed)
end



