%% PRE-LAUNCH DAY ROCKET NOSE MASS OPTIMIZATION
%
% Description:
% This script estimates the optimal nose cone ballast mass for a rocket
% by analyzing weather forecasts over a specified time window. It defines a
% nominal launch time, fetches GFS forecast data (temperature and wind)
% for each interval in that window, and then runs an optimization for each
% forecast to find the mass required to hit a target apogee. The script
% then reports the average required mass to aid in pre-launch preparation.
%
% v2.0 - Corrected to fetch atmosphere data for each time step individually.
%
% Instructions:
% 1. Ensure the 'openrocket' function and the rocket file are on the MATLAB path.
% 2. Adjust the parameters in the "User Parameters" section below.
% 3. Run the script.

% Housekeeping
clear;
close all;
clc;

%% ------------------------- User Parameters ------------------------- %%

% --- Launch & Site ---
rocket_file = "rocket_files\IREC_2025_M6000ST-0.ork";
sim_name    = "10MPH-TEXAS-36C-(TYP)";
site_name   = "spaceport-midland";
nose_cmp_name = 'Adjustable stability weight(s)'; % Name of the adjustable mass component in OpenRocket

% --- Time Window ---
% Define the center of your potential launch window
% NOTE: The current date is June 7, 2025. GFS forecasts are typically
% available for up to 10-16 days in the future. A launch_time in 2024
% will likely fail to retrieve a forecast. Setting to a valid future date.
nominal_launch_time = datetime(2025, 06, 07, 10, 00, 00, TimeZone = "-06:00");

% Define the time range to analyze around the nominal time (e.g., ±3 hours)
time_window_hours = 3;
% Define the interval for analysis (e.g., check weather every 1 hour)
time_step_hours = 1;

% --- Optimization Target ---
target_apogee_ft = 10700;       % Desired apogee [ft]
mass_min_kg      = 0.0;         % Lower bound for nose mass search [kg]
mass_max_kg      = 2.5;         % Upper bound for nose mass search [kg]
tolerance_ft     = 10;          % Optimizer stops if |apogee_error| < tolerance_ft

% --- Puck System (for discrete mass calculation, optional) ---
pucks_g = [1645 795 390 195 95 45]; % Available discrete puck masses [grams]

%% ------------------- Script Execution (No Edits Below) ------------------- %%

fprintf('--- Rocket Nose Mass Optimization ---\n');

% 1. SETUP LAUNCH WINDOW & ROCKET
% --------------------------------------------------------------------------
fprintf('1. Initializing...\n');
% Create the array of datetime objects to be analyzed
launch_window = nominal_launch_time + hours(-time_window_hours:time_step_hours:time_window_hours);
fprintf('   Analyzing %d time slots from %s to %s\n', ...
    numel(launch_window), string(launch_window(1)), string(launch_window(end)));

% Load rocket and simulation details
otis = openrocket(rocket_file);
sim  = otis.sims(sim_name);
site = launchsites(site_name);
nose_component = otis.component('name', nose_cmp_name);
ft2m = 0.3048; % Conversion factor

% 2. PREPARE FOR SIMULATION LOOP
% --------------------------------------------------------------------------
fprintf('2. Preparing to run optimization for each time slot...\n');
num_sims = numel(launch_window);
optimal_masses_kg = nan(1, num_sims);

% get the latest data from noaa
utc_now  = datetime('now','TimeZone','UTC') - hours(2);    % leave ~2 h for files to land
cyc_hour = floor(hour(utc_now)/1)*1;                       % HRRR cycles are hourly
reftime  = datetime(year(utc_now),month(utc_now),day(utc_now),cyc_hour,0,0,'TimeZone','UTC');

% one object for the whole window ─ it already carries all lead times
hrrr = ncep.forecast("hrrr","wrfprsf",launch_window,reftime);


% 3. RUN SIMULATION FOR EACH FORECAST TIME
% --------------------------------------------------------------------------
wbar = waitbar(0, 'Starting simulations...');

for i = 1:num_sims
    current_time = launch_window(i);
    
    % --- FIX starts here ---
    % Fetch weather data for the CURRENT time step inside the loop
    waitbar_msg = sprintf('Fetching weather for %s...', string(current_time));
    waitbar((i-1)/num_sims, wbar, waitbar_msg);
    
    try
        airdata = hrrr.read_point(site.lat,site.lon, ...
            layer = digitsPattern+" mb", ...
            field = ["UGRD","VGRD","HGT","TMP"], ...
            time  = current_time);                 % specific lead time
    catch ME
        fprintf('\n⟡ no HRRR file yet for %s → skip\n',string(current_time));
        fprintf('  (%s)\n',ME.message);
        continue
    end

    % Update waitbar
    waitbar_msg = sprintf('Optimizing for %s (%d/%d)', string(current_time), i, num_sims);
    waitbar((i-0.5)/num_sims, wbar, waitbar_msg);
    
    % Extract weather for the current time step (at 2m for temp, 10m for wind)
    % The fetched 'airdata' is now specific to 'current_time'
    launch_temp_C = airdata.TMP(airdata.HGT == 2);
    
    % Handle cases where exact altitude data is missing by interpolating
    if isempty(launch_temp_C)
        launch_temp_C = interp1(airdata.HGT, airdata.TMP, 2, 'linear', 'extrap');
    end
    
    u_wind_10m = airdata.UGRD(airdata.HGT == 10);
    v_wind_10m = airdata.VGRD(airdata.HGT == 10);
    
    if isempty(u_wind_10m) || isempty(v_wind_10m)
        u_wind_10m = interp1(airdata.HGT, airdata.UGRD, 10, 'linear', 'extrap');
        v_wind_10m = interp1(airdata.HGT, airdata.VGRD, 10, 'linear', 'extrap');
    end

    wind_speed_ms = sqrt(u_wind_10m^2 + v_wind_10m^2);
    
    % Run optimization to find the required nose mass
    fprintf('   -> Sim %d/%d: %.1f°C, %.1f m/s wind... ', i, num_sims, launch_temp_C, wind_speed_ms);
    
    req_mass_kg = nm_getmass(launch_temp_C, wind_speed_ms, otis, sim, nose_component, ...
                             target_apogee_ft, mass_min_kg, mass_max_kg, tolerance_ft, ft2m);
    
    optimal_masses_kg(i) = req_mass_kg;
    
    if ~isnan(req_mass_kg)
        fprintf('Success. Mass = %.3f kg\n', req_mass_kg);
    else
        fprintf('Failed.\n');
    end
    waitbar(i/num_sims, wbar);
end

close(wbar);

% 4. REPORT RESULTS
% --------------------------------------------------------------------------
fprintf('4. Analysis Complete.\n');

avg_mass_kg = mean(optimal_masses_kg, 'omitnan');
std_dev_kg  = std(optimal_masses_kg, 'omitnan');

if ~isnan(avg_mass_kg)
    [puck_combo_g, residual_g] = split_into_pucks(avg_mass_kg, pucks_g);
    
    fprintf('\n--- LAUNCH DAY RECOMMENDATION ---\n');
    fprintf('Analysis Window:      %s to %s\n', string(launch_window(1)), string(launch_window(end)));
    fprintf('Target Apogee:        %d ft\n', target_apogee_ft);
    fprintf('-------------------------------------\n');
    fprintf('Average Nose Mass:    %.3f kg (%.0f g)\n', avg_mass_kg, avg_mass_kg*1000);
    fprintf('Standard Deviation:   %.3f kg (%.0f g)\n', std_dev_kg, std_dev_kg*1000);
    fprintf('-------------------------------------\n');
    fprintf('Recommended Pucks (g): %s\n', mat2str(puck_combo_g));
    fprintf('Puck Total Weight:     %.0f g\n', sum(puck_combo_g));
    fprintf('Residual (unfilled):   %.0f g\n', residual_g);
    fprintf('-------------------------------------\n');
else
    fprintf('\n--- ANALYSIS FAILED ---\n');
    fprintf('Could not determine an average mass. All optimization runs failed to converge or retrieve weather.\n');
end

%% ------------------------- Local Functions ------------------------- %%
% (These functions remain unchanged)

function reqMass_kg = nm_getmass(launchTemp_C, wind_ms, otis, simObj, noseCmp, ...
                                 targetApogee_ft, noseMin_kg, noseMax_kg, tol_ft, ft2m)
%REQ_NOSEMASS Computes required nose-cone ballast to hit a target apogee.
    costFun = make_cost_function(otis, simObj, noseCmp, ...
                                 wind_ms, launchTemp_C, ...
                                 targetApogee_ft, ft2m, ...
                                 noseMin_kg, noseMax_kg);
    opts = optimset('Display','none', 'TolFun',tol_ft, 'TolX',0.002);
    m0 = 0.5 * (noseMin_kg + noseMax_kg);
    [reqMass_kg, fval, exitflag] = fminsearch(costFun, m0, opts);
    if exitflag <= 0 || fval > tol_ft
        reqMass_kg = NaN;
    end
end

function func = make_cost_function(otis, simObj, cmp, ...
                                   W_ms, launchTemp_C, ...
                                   target_ft, ft2m, ...
                                   lo_kg, hi_kg)
%MAKE_COST_FUNCTION Returns a handle @(m) that gives altitude error [ft].
    opts = simObj.getOptions();
    opts.setWindSpeedAverage(W_ms);
    opts.setWindSpeedDeviation(0);
    opts.setLaunchIntoWind(false);
    opts.setTimeStep(0.05);
    opts.setLaunchTemperature(launchTemp_C + 273.15); % °C → K
    func = @cost;
    function err = cost(x)
        m = min(max(x(1), lo_kg), hi_kg);
        cmp.setOverrideMass(m);
        cmp.setComponentMass(m);
        data = otis.simulate(simObj, 'outputs','ALL');
        apogee_ft = max(data.Altitude) / ft2m;
        err = abs(apogee_ft - target_ft);
    end
end

function [combo, res] = split_into_pucks(req_kg, pucks_g)
%SPLIT_INTO_PUCKS Decomposes a required mass into a list of discrete pucks.
    remaining_g = round(req_kg * 1000);
    combo = [];
    for p = pucks_g
        if remaining_g >= p
            combo(end+1) = p; %#ok<AGROW>
            remaining_g = remaining_g - p;
        end
    end
    res = remaining_g;
end