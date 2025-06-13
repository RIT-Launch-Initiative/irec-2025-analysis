clear; close all; clc;

%% OPENROCKET SETUP
otis_path = "rocket_files/IREC_2025_M6000ST-0.ork";
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end
otis = openrocket(otis_path);
sim  = otis.sims("10MPH-TEXAS-36C-(TYP)");
opts = sim.getOptions();


%% CUSTOM ATMOSPHERE SETUP
% pull GFS‐based profile instead of the default std atmosphere
air     = load("scripts\irec\airdata_cache\hrr_wed_morn\airdata_20250611_1200.mat").airdata;
atmData = air(:, ["HGT","PRES","TMP","UGRD","VGRD"]);             % pass this to simulate
atmData.TMP = atmData.TMP + 273.15;


%% MONTE CARLO PARAMS
rod_direction = 150;
nSims                  = 1;    % at least 100 for design review
wind_speed_avg         = 4.47;   % m/s
wind_speed_spread      = 1.3;   % m/s
wind_speed_deviation   = 0;
wind_direction_mean    = 120;     % degrees
wind_direction_spread  = 20;    % full circle
nominal_temp = 29; % c
temp_spread            = 6;     % °C around launch‐site nominal
turbulence_intensity   = 0.0;
time_step              = 0.05;  % s
tol                    = 0.1;    % for settling‐time threshold

%% PREALLOCATE
data_wind_speeds    = zeros(1,nSims);
data_wind_dirs      = zeros(1,nSims);
data_temp_init      = zeros(1,nSims);
data_apogee         = zeros(1,nSims);
data_stabOffRod     = zeros(1,nSims);
data_time_to_stab   = zeros(1,nSims);
data_settle_time    = zeros(1,nSims);
data_overshoot      = zeros(1,nSims);
data_settle_thresh  = zeros(nSims,1);
t_burn              = 1.736;  % sec
t_launch            = 0.255;  % sec
tsteps              = 1 + (3 + t_burn - t_launch)/time_step;
data_aoa            = zeros(ceil(tsteps),nSims);

%% RUN MONTE CARLO
for I = 1:nSims
    % randomize environmental inputs
    opts.setLaunchIntoWind(true);
    wind_dir = wind_direction_mean + (rand-0.5)*wind_direction_spread;
    opts.setWindDirection(deg2rad(wind_dir));
    opts.setWindTurbulenceIntensity(turbulence_intensity);
    % opts.setWindSpeedAverage(wind_speed_avg + (rand-0.5)*wind_speed_spread);
    launchTemp = nominal_temp + (rand-0.5)*temp_spread;
    opts.setLaunchTemperature(launchTemp+273.15);
    opts.setLaunchRodDirection(deg2rad(rod_direction));
    opts.setTimeStep(time_step);
    
    % simulate using custom atmosphere
    data = otis.simulate(sim,'outputs','Altitude', ...
                         atmos=atmData(:,["HGT","PRES","TMP","UGRD","VGRD"]));

    
    % record raw outputs
    data_wind_speeds(I) =  opts.getWindSpeedAverage
    data_wind_dirs(I)   = wind_dir;
    data_temp_init(I)   = launchTemp; % back to °C
    data_apogee(I)      = max(data.Altitude);
    
    % isolate launch‐rod to +3 s post‐burn
    lrIdx = eventfilter("LAUNCHROD");
    brIdx = eventfilter("BURNOUT");
    t_launch = data.Time(lrIdx);
    t_burn = seconds(1.736); %unknown reason why this was returning 0x1 matrix. set hard value instead. works now /shrug. thx chatgpt
    tr = timerange(t_launch, t_burn+seconds(3), "open");
    sub = data(tr,:);
    
    % stability margin off‐rod & AOA
    data_stabOffRod(I)     = min(data.("Stability margin"));
    rawAOA                  = sub.("Angle of attack");
    aoa_clean               = cleanAOA(time_step, rawAOA);
    n = height(aoa_clean);
    data_aoa(1:n,I)        = aoa_clean;
    
    % settling time & overshoot
    aoa_deg               = rad2deg(rawAOA);
    init_val              = aoa_deg(1);
    thresh                = tol*init_val;
    data_settle_thresh(I) = thresh;
    idx_over = find(aoa_deg>thresh,1,'last');
    data_settle_time(I)   = seconds(sub.Time(idx_over));
    data_overshoot(I)     = computeOvershoot(aoa_deg);
    
    % time to reach stability margin ≥1.5
    if data_stabOffRod(I) >= 1.5
        data_time_to_stab(I) = 0;
    else
        times = seconds(sub.Time);
        margins = sub{:, 'Stability margin'};
        if any(margins>=1.5)
            data_time_to_stab(I) = interp1(margins, times, 1.5) - times(1);
        else
            data_time_to_stab(I) = NaN;
        end
    end
    
    opts.randomizeSeed;    % new seed each run
    fprintf('Sim %d done\n', I);
end

%% EXPORT RESULTS
outFile = fullfile(pwd, "simulation_results_customATM.xlsx");
exportResultsToExcel(outFile, ...
    data_wind_speeds, data_temp_init, data_wind_dirs, ...
    data_apogee, data_stabOffRod, data_time_to_stab, ...
    data_settle_time, data_overshoot, data_settle_thresh, ...
    data_aoa, time_step);



max_wind = max(data_wind_speeds);
min_wind = min(data_wind_speeds);
wind_range = max_wind-min_wind;
avg_wind = (max_wind-min_wind)/2;

max_wind_dir = max(data_wind_dirs);
min_wind_dir = min(data_wind_dirs);
wind_dir_range = max_wind_dir-min_wind_dir;
avg_wind_dir = (max_wind_dir-min_wind_dir)/2;

max_temperature = max(data_temp_init);
min_temperature = min(data_temp_init);
temp_range = max_temperature-min_temperature;
avg_temp = (max_temperature-min_temperature)/2;

% linear reg coefs
wind_sped_coef = -4.82;
temp_coef = 0.388;
wind_dir_coef= -0.823;
wid_dir_sqrd_coef = 0.002766;

% stackup
wind_stack = wind_sped_coef*wind_range
temp_stack = temp_coef*temp_range
wind_dir_stack = wind_dir_coef*wind_dir_range+wind_dir_range^2*wid_dir_sqrd_coef
total_stack = wind_stack+temp_stack+wind_dir_stack




%% — helper functions (computeOvershoot, cleanAOA, exportResultsToExcel) here as before

function overshoot = computeOvershoot(A_array)
    % compute final value
    initial_val = A_array(1);
    final_val   = A_array(end,1);

    % first‑peak overshoot
    if final_val >= initial_val
        [~, locs] = findpeaks(A_array);
    else
        [~, locs] = findpeaks(-A_array);
    end
    idx_peak   = locs(1) * ( ~isempty(locs) ) + ( isempty(locs) ); 
    peak_val   = A_array(idx_peak);
    % overshoot %
    overshoot = abs(peak_val - final_val) / max(abs(final_val - initial_val), eps) * 100;
end


function A_signed = cleanAOA(dt, aoa_rad)
% CLEANAOA  Undo the “bounce” in an absolute AOA trace.
%   A_signed = cleanAOA(dt, aoa_rad)
%   (dt is unused here but kept for API compatibility)

    zero_thresh_deg = 0.1;

    % convert to degrees
    A_abs = rad2deg(aoa_rad);    % this is 150×1

    % find “valley” points
    prom   = max(zero_thresh_deg/2, 1e-4);
    [~, v] = findpeaks(-A_abs, 'MinPeakProminence', prom);
    v      = sort(v(:)');

    % build sign vector with the same shape as A_abs
    signVec = ones(size(A_abs));  % now also 150×1
    s       = 1;
    last    = 1;
    for idx = v
        signVec(last:idx) = s;
        s                 = -s;
        last              = idx+1;
    end
    signVec(last:end) = s;

    % element‑wise multiply
    A_signed = signVec .* A_abs;  % still 150×1
end



%% –– function definition ––
function exportResultsToExcel(filename, windSpd, temp, windDir, apogee, stabOffRod, tToStab, tSettle, overshoot, thresh, aoaMat, dt)
    n = numel(windSpd);
    sims = (1:n)';
    
    % build summary table
    T = table(sims, windSpd(:), temp(:), windDir(:), apogee(:), ...
              stabOffRod(:), tToStab(:), tSettle(:), overshoot(:), thresh(:), ...
              'VariableNames', { ...
                'Sim','WindSpeed_mps','Temperature_C','WindDir_deg', ...
                'Apogee_ft','StabilityOffRod_cal','TimeTo1p5_cal_s', ...
                'SettleTime_s','Overshoot_pct','SettleThreshold_deg'});
    writetable(T, filename, 'Sheet', 'Summary');
    
    % time vector for AOA series
    tVec = (0:size(aoaMat,1)-1)' * dt;
    A = array2table(aoaMat, 'VariableNames', compose("Sim%02d", 1:n));
    A = addvars(A, tVec, 'Before', 1, 'NewVariableNames', 'Time_s');
    writetable(A, filename, 'Sheet', 'AOA');
end

mean_real_apogee=mean(data_apogee-600)