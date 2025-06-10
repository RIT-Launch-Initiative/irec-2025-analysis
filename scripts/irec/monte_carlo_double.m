% ──────────────────────────────────────────────────────────────────────────
% MONTE‑CARLO ROCKET SIM + OVERLAYED HISTOGRAMS
% Kyle Scher – RIT – 2025‑06‑09
% ──────────────────────────────────────────────────────────────────────────
clear; close all; clc;

%% ── OPENROCKET SETUP ────────────────────────────────────────────────────
otis_path = "rocket_files/IREC_2025_M6000ST-0.ork";
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end
otis = openrocket(otis_path);
sim  = otis.sims("10MPH-TEXAS-36C-(TYP)");
opts = sim.getOptions();

%% ── CUSTOM ATMOSPHERE ───────────────────────────────────────────────────
air     = load("rocket_files/midland_atmosphere.mat").airdata;
atmData = air(:,["HGT","PRES","TMP"]);
atmData.TMP = atmData.TMP + 273.15;           % convert °C→K

%% ── DEFINE TEST SCENARIOS HERE ──────────────────────────────────────────
params = [ ...
    struct( ...                    % Scenario A – baseline
        'label',              "Innacurate", ...
        'nSims',              100, ...
        'wind_speed_avg',     6.7, ...
        'wind_speed_spread',  2.7, ...
        'wind_direction_mean',150, ...
        'wind_direction_spread',100, ...
        'nominal_temp',       25, ...
        'temp_spread',        10, ...
        'rod_direction',      150, ...
        'turb_intensity',     0.00 ...
    ), ...
    struct( ...                    % Scenario B – windier
        'label',              "Accurate", ...
        'nSims',              100, ...
        'wind_speed_avg',     4, ...
        'wind_speed_spread',  1.5, ...
        'wind_direction_mean',120, ...
        'wind_direction_spread',20, ...
        'nominal_temp',       23, ...
        'temp_spread',        8, ...
        'rod_direction',      150, ...
        'turb_intensity',     0.00 ...
    ) ...
];

%% ── STORAGE FOR RESULTS ────────────────────────────────────────────────
apogee_ft       = cell(size(params));   % apogees per scenario
error_from_10k  = cell(size(params));   % deviation from 10 000 ft

%% ── MAIN MONTE‑CARLO LOOP ───────────────────────────────────────────────
time_step = 0.025;                      % used by helper functions (if needed)

for s = 1:numel(params)
    P   = params(s);                    % shorthand
    apo = zeros(1,P.nSims);             % pre‑allocate apogees

    for k = 1:P.nSims
        % Randomise environmental inputs
        opts.setLaunchIntoWind(false);
        wdir = P.wind_direction_mean + (rand-0.5)*P.wind_direction_spread;
        opts.setWindDirection(deg2rad(wdir));
        opts.setWindTurbulenceIntensity(P.turb_intensity);
        opts.setWindSpeedAverage(P.wind_speed_avg + (rand-0.5)*P.wind_speed_spread);
        Ltemp = P.nominal_temp + (rand-0.5)*P.temp_spread;
        opts.setLaunchTemperature(Ltemp + 273.15);
        opts.setLaunchRodDirection(deg2rad(P.rod_direction));
        opts.setTimeStep(time_step);

        % Run simulation
        data   = otis.simulate(sim,'outputs','ALL','atmos',atmData);
        % inside the inner loop
        apo(k) = max(data.Altitude) * 3.28084;   % metres → ft

        opts.randomizeSeed;             % new seed each run
    end

    % Store results
    apogee_ft{s}      = apo;
    error_from_10k{s} = apo - 10000;    % deviation from 10 000 ft

    fprintf("Scenario “%s” complete (%d runs)\n", P.label, P.nSims);
end

%% ── OPTIONAL EXCEL EXPORT PER SCENARIO ─────────────────────────────────
%{
for s = 1:numel(params)
    outFile = fullfile(pwd, sprintf("simulation_results_%s.xlsx", params(s).label));
    % Dummy inputs for helper (only providing what’s required)
    exportResultsToExcel(outFile, ...
        apogee_ft{s}, zeros(size(apogee_ft{s})), zeros(size(apogee_ft{s})), ...
        apogee_ft{s}, ones(size(apogee_ft{s})), zeros(size(apogee_ft{s})), ...
        zeros(size(apogee_ft{s})), zeros(size(apogee_ft{s})), ...
        zeros(size(apogee_ft{s})), zeros(size(apogee_ft{s})), ...
        zeros(1), time_step);
end
%}

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
    % overshoot % (avoid division by zero with eps)
    overshoot = abs(peak_val - final_val) / max(abs(final_val - initial_val), eps) * 100;
end

function A_signed = cleanAOA(~, aoa_rad)
% CLEANAOA  Undo the “bounce” in an absolute AOA trace.
    zero_thresh_deg = 0.1;

    % convert to degrees
    A_abs = rad2deg(aoa_rad);

    % find “valley” points
    prom   = max(zero_thresh_deg/2, 1e-4);
    [~, v] = findpeaks(-A_abs, 'MinPeakProminence', prom);
    v      = sort(v(:)');

    % build sign vector
    signVec = ones(size(A_abs));
    s   = 1; last = 1;
    for idx = v
        signVec(last:idx) = s;
        s                 = -s;
        last              = idx+1;
    end
    signVec(last:end) = s;

    % apply signs
    A_signed = signVec .* A_abs;
end

function exportResultsToExcel(filename, windSpd, temp, windDir, apogee, ...
        stabOffRod, tToStab, tSettle, overshoot, thresh, aoaMat, dt)
    n = numel(windSpd);
    sims = (1:n)';

    % summary table
    T = table(sims, windSpd(:), temp(:), windDir(:), apogee(:), ...
              stabOffRod(:), tToStab(:), tSettle(:), overshoot(:), thresh(:), ...
              'VariableNames', { ...
                'Sim','WindSpeed_mps','Temperature_C','WindDir_deg', ...
                'Apogee_ft','StabilityOffRod_cal','TimeTo1p5_cal_s', ...
                'SettleTime_s','Overshoot_pct','SettleThreshold_deg'});
    writetable(T, filename, 'Sheet', 'Summary');

    % AOA matrix
    tVec = (0:size(aoaMat,1)-1)' * dt;
    A = array2table(aoaMat, 'VariableNames', compose("Sim%02d", 1:n));
    A = addvars(A, tVec, 'Before', 1, 'NewVariableNames', 'Time_s');
    writetable(A, filename, 'Sheet', 'AOA');
end
