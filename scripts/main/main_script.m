% This script will collect all of the data in various scripts for you and
% collect it
close all;clear; 


addpath(genpath("C:\\lmatlib"))
addpath(genpath("C:\lmatlib\sim"));

% open rocket integration intitialize 
otis_path = "C:\\irec-2025-analysis\\IREC_2025_M6000ST-0.ork";
otis = openrocket(otis_path);
sim = otis.sims("10MPH-TEXAS-36C-(TYP)"); %from openrocket
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end

% open rocket integration config
opts = sim.getOptions();

%Monte carlo variables
nSims = 250; % change this to increase number of iterations. higher is better. minimum for any design review is 100 
wind_speed = 4.47; %m/s
wind_speed_spread = 4.47; % m/s
wind_speed_devation = (wind_speed/10);
wind_direction = 45;
temp_spread = 10; % c
temp = opts.getLaunchTemperature;
wind_direction_spread = 360;
time_step = 0.025;
turb = 0.15;
tol         = 0.1;

%conversion factors
m_sTOmph = 2.237136;
meterTofoot = 3.28084;
sTomS = 1/1000;

%initialize 
data_stabilityOffRod = zeros(1, nSims);
data_wind_speeds = zeros(1,nSims);
data_temp = zeros(1,nSims);
data_wind_direciton = zeros(1,nSims);
data_apogee = zeros(1,nSims);
data_time_to_stab = zeros(1,nSims);
data_settle_time = zeros(1,nSims);
data_overshoot      = zeros(1, nSims);
t_burn = 1.736;
t_launch = 0.255;
tsteps = 1+(3+t_burn-t_launch)/time_step;
data_aoa = zeros((ceil(tsteps)),nSims);
data_settle_threshold = zeros(nSims,1);
data_pitch_moment = zeros((ceil(tsteps)),nSims);


for I = 1:nSims

    % set randomized sim variable
    opts.setLaunchIntoWind(false);
    wind_dir = wind_direction+(rand()-0.5)*wind_direction_spread;
    opts.setWindDirection(wind_dir);  
    opts.setWindTurbulenceIntensity(turb)
    opts.setWindSpeedAverage(wind_speed + (rand()-0.5)*wind_speed_spread);
    opts.setLaunchTemperature(temp + (rand()-0.5)*temp_spread);
    opts.setTimeStep(time_step)
    opts.setWindSpeedDeviation(wind_speed_devation)



    % run simulation
    data = openrocket.simulate(sim, outputs = "ALL");
    data_apogee(1,I) = max(data.Altitude);

    %limit data range
    data_range = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
    launchRow = eventfilter("LAUNCHROD");
    burnRow = eventfilter("BURNOUT"); 

    t_launch = data.Time(launchRow);
    t_burn = data.Time(burnRow);
    tr = timerange(t_launch, t_burn + seconds(3), "open");

    data = data(data_range, :);
    data_burnout_plus3 = data(tr, :);

    % collect interesting information
    stabilityMargin = data{:, 'Stability margin'};
  
    rawaoa = data_burnout_plus3.("Angle of attack");
    aoa_clean = cleanAOA(time_step,rawaoa);
    data_aoa (:,I) = aoa_clean;  
    data_stabilityOffRod (1,I) = data{1, 'Stability margin'};

    % compute settling time & overshoot
    aoa_rad       = data_burnout_plus3.("Angle of attack");
    aoa_deg  = rad2deg(aoa_rad);

    initial_val = aoa_deg(1);
    final_val   = 0;             
    thresh      = final_val + tol*initial_val;
    data_settle_threshold (I) = thresh;

    i_over = find(aoa_deg > thresh, 1, "last");
    settle_time = seconds(data.Time(i_over));

    overshoot = computeOvershoot(aoa_deg);

    data_settle_time(I) = settle_time;
    data_overshoot(I)   = overshoot;

    % time to stability 1.5 data
    if data_stabilityOffRod(1,I) >= 1.5
        data_time_to_stab(1,I) = 0;
    else
        % Define the subarray starting at index 127
        marginSubarray = stabilityMargin(1:end);
        timeSubarray = seconds(data.Time(1:end));

        if any(marginSubarray >= 1.5)% Find the index range where stabilityMargin crosses 1.5
            % Use interp1 to find the exact time where stabilityMargin reaches 1.5
            data_time_to_stab(1,I) = (interp1(marginSubarray, timeSubarray, 1.5))-(timeSubarray(1,1));
        else
            data_time_to_stab(1,I) = NaN;  % No stability achieved
        end    
    end

    % save data
    data_wind_speeds(1,I) = data{1,"Wind velocity"};
    data_temp(1,I) = data{1,"Air temperature"};
    data_wind_direciton(1,I) = wind_dir;

    % randomize and display
    opts.randomizeSeed    
    disp(I)

end

% specify output file
outFile = fullfile(pwd, "simulation_results.xlsx");

% call the exporter
exportResultsToExcel(outFile, ...
    data_wind_speeds, data_temp-273.15, data_wind_direciton, ...
    data_apogee, data_stabilityOffRod, data_time_to_stab, ...
    data_settle_time, data_overshoot, data_settle_threshold, ...
    data_aoa, time_step);


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