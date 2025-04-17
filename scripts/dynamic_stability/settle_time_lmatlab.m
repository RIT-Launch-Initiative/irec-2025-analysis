%% Clear Workspace and Close Figures
clear; close all; clc;

%% Constants and Unit Conversions
ft_to_m       = 0.3048;           
lbft2_to_kgm2 = 1.35581795;       
oz_to_kg      = 0.0283495;        
in_to_m       = 0.0254;           
in2_to_m2     = 0.00064516;       

%% File Paths and Simulation Names
addpath(genpath("C:\lmatlib"));

% file 1
ork_file_path1 = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
sim_name1      = "15MPH-TEXAS-36C-(TYP)";

% file 2
ork_file_path2 = "C:\irec-2025-analysis\IREC 2024.ork";
sim_name2      = "Spaceport America 0 MPH Case";

% parameters shared by both simulations
time                 = 1.5;      % seconds
winddirection        = 0;
wind_speed           = 4.47;
temperature          = 27;
time_step            = 0.001;
launch_angle         = 6;
launchrod_direction  = 0;

% threshold below which AOA is treated as "zero" for bounce‑undo (deg)
zero_thresh_deg      = 0.05;

%% === Simulation 1 ===
otis1 = openrocket(ork_file_path1);
sim1  = otis1.sims(sim_name1);
opts1 = sim1.getOptions;
opts1.setWindDirection(winddirection);
opts1.setWindTurbulenceIntensity(0);
opts1.setWindSpeedAverage(wind_speed);
opts1.setLaunchTemperature(temperature);
opts1.setTimeStep(time_step);
opts1.setLaunchRodAngle(launch_angle);
opts1.setLaunchRodDirection(launchrod_direction);

openrocket.simulate(sim1);
data1 = openrocket.get_data(sim1);

data_range1 = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
data1       = data1(data_range1, :);

rod_exit_time1 = data1.Time(1);
time_flight1   = seconds(data1.Time - rod_exit_time1);

valid_1        = (time_flight1 <= time);
time_flight1   = time_flight1(valid_1);
aoa1_rad       = data1.("Angle of attack")(valid_1);
A_flight1_abs  = rad2deg(aoa1_rad);

% --- Undo OpenRocket "bounce" so signal alternates ± about zero
A_flight1      = restoreSigned(A_flight1_abs, zero_thresh_deg);

% --- Compute metrics
metrics_flight1 = computeMetrics(time_flight1, A_flight1);

%% === Simulation 2 ===
otis2 = openrocket(ork_file_path2);
sim2  = otis2.sims(sim_name2);
opts2 = sim2.getOptions;
opts2.setWindDirection(winddirection);
opts2.setWindTurbulenceIntensity(0);
opts2.setWindSpeedAverage(wind_speed);
opts2.setLaunchTemperature(temperature);
opts2.setTimeStep(time_step);
opts2.setLaunchRodAngle(launch_angle);
opts2.setLaunchRodDirection(launchrod_direction);

openrocket.simulate(sim2);
data2 = openrocket.get_data(sim2);

data_range2 = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
data2       = data2(data_range2, :);

rod_exit_time2 = data2.Time(1);
time_flight2   = seconds(data2.Time - rod_exit_time2);

valid_2        = (time_flight2 <= time);
time_flight2   = time_flight2(valid_2);
aoa2_rad       = data2.("Angle of attack")(valid_2);
A_flight2_abs  = rad2deg(aoa2_rad);
A_flight2      = restoreSigned(A_flight2_abs, zero_thresh_deg);

metrics_flight2 = computeMetrics(time_flight2, A_flight2);

%% === Plot ===
figure('Name','AOA (Signed) Aligned at Off‑the‑Rod');  hold on;

h1 = plot(time_flight1, A_flight1, 'LineWidth',1.5, 'DisplayName','OTIS');
h2 = plot(time_flight2, A_flight2, 'LineWidth',1.5, 'DisplayName','OMEN');

set(gca,'YDir','reverse');           % keep if you still want the axis flipped
xlabel('Time After Rod Exit (s)');
ylabel('AOA (deg, signed)');
title('AOA Comparison with Bounce Removal');
legend('Location','best');
grid on;

% ---------- Overshoot markers & labels ----------
% --- Simulation 1 ---
plot(metrics_flight1.peak_time, metrics_flight1.peak_val, 'o', ...
     'MarkerFaceColor', h1.Color, 'MarkerEdgeColor', h1.Color, ...
     'HandleVisibility','off');

line([metrics_flight1.peak_time metrics_flight1.peak_time], ...
     [metrics_flight1.final_val metrics_flight1.peak_val], ...
     'Color', h1.Color, 'LineStyle','--', 'HandleVisibility','off');

text(metrics_flight1.peak_time, metrics_flight1.peak_val, ...
     sprintf('  %.1f%%', metrics_flight1.overshoot), ...
     'Color', h1.Color, 'FontWeight','bold', 'VerticalAlignment','bottom');

% --- Simulation 2 ---
plot(metrics_flight2.peak_time, metrics_flight2.peak_val, 'o', ...
     'MarkerFaceColor', h2.Color, 'MarkerEdgeColor', h2.Color, ...
     'HandleVisibility','off');

line([metrics_flight2.peak_time metrics_flight2.peak_time], ...
     [metrics_flight2.final_val metrics_flight2.peak_val], ...
     'Color', h2.Color, 'LineStyle','--', 'HandleVisibility','off');

text(metrics_flight2.peak_time, metrics_flight2.peak_val, ...
     sprintf('  %.1f%%', metrics_flight2.overshoot), ...
     'Color', h2.Color, 'FontWeight','bold', 'VerticalAlignment','bottom');

%% === Display Metrics ===
fprintf('\n=== Response Metrics (Aligned at Rod Exit Time) ===\n\n');

fprintf('--- Simulation 1: %s ---\n', sim_name1);
displayMetrics(metrics_flight1);

fprintf('\n--- Simulation 2: %s ---\n', sim_name2);
displayMetrics(metrics_flight2);

%% === LOCAL FUNCTIONS ===

function A_signed = restoreSigned(A_abs, threshold)
    % RESTORESIGNED  Convert "bouncing" absolute‑value AOA trace into a true
    %                signed waveform by toggling the sign only at well‑defined
    %                valley minima. This hysteresis‑style approach removes the
    %                tiny sign‑flip "hiccups" near zero.
    %
    %   A_signed = restoreSigned(A_abs, threshold)
    %
    % Inputs:
    %   A_abs     : original non‑negative AOA array
    %   threshold : value (deg) that determines what counts as a valley
    %
    % Algorithm:
    %   1. Find valley minima using findpeaks on the inverted signal with a
    %      prominence tied to the threshold (robust against noise).
    %   2. Starting with a positive sign, flip the sign **once** at each
    %      valley index. Samples between successive valleys keep the same
    %      sign, eliminating rapid toggles.

    if nargin < 2
        threshold = 0.05;  % deg
    end

    % Identify valley minima (potential zero‑bounce points)
    prominence = max(threshold/2, 1e-4);
    [~, valley_idx] = findpeaks(-A_abs, 'MinPeakProminence', prominence);

    valley_idx = sort(valley_idx(:)');  % row vector

    % Build sign vector that flips at each valley
    sign_vec  = ones(size(A_abs));
    sign_flag = 1;
    last_idx  = 1;
    for i = 1:numel(valley_idx)
        this_idx = valley_idx(i);
        sign_vec(last_idx:this_idx) = sign_flag;
        sign_flag = -sign_flag;          % flip
        last_idx  = this_idx+1;
    end
    sign_vec(last_idx:end) = sign_flag;  % tail segment

    A_signed = sign_vec .* A_abs;

    % Optional: tiny smoothing to wipe out single‑sample glitches (comment out if undesired)
    % A_signed = movmean(A_signed, 3);
end

function metrics = computeMetrics(time_array, A_array)
    % COMPUTEMETRICS  Calculates step‑response style metrics for AOA data.
    % Overshoot is referenced to the first positive‑going peak following a
    % zero crossing from negative to positive.

    initial_val = A_array(1);
    n_final     = max(1, round(0.1*length(A_array)));
    final_val   = mean(A_array(end - n_final + 1 : end));

    %% Rise‑time (10‑90 %)
    if final_val >= initial_val
        level10 = initial_val + 0.1*(final_val - initial_val);
        level90 = initial_val + 0.9*(final_val - initial_val);
        idx10   = find(A_array >= level10, 1, 'first');
        idx90   = find(A_array >= level90, 1, 'first');
    else
        level10 = initial_val - 0.1*(initial_val - final_val);
        level90 = initial_val - 0.9*(initial_val - final_val);
        idx10   = find(A_array <= level10, 1, 'first');
        idx90   = find(A_array <= level90, 1, 'first');
    end

    rise_time = NaN;
    if ~isempty(idx10) && ~isempty(idx90)
        rise_time = time_array(idx90) - time_array(idx10);
    end

    %% Overshoot — first local extreme after t = 0
    if final_val >= initial_val          % rising response → look for a max
    [~, locs] = findpeaks(A_array);
    else                                 % falling response → look for a min
    [~, locs] = findpeaks(-A_array);
    end
    
    if isempty(locs)                     % totally flat: no peak
    idx_peak = 1;
    else
    idx_peak = locs(1);              % first extreme is the overshoot
    end
    
    peak_val  = A_array(idx_peak);
    peak_time = time_array(idx_peak);
    
    overshoot = abs(peak_val - final_val) / ...
            max(abs(final_val - initial_val), eps) * 100;

    %% Settling time (±5 %)
    tolerance     = 0.02;
    band          = tolerance * abs(final_val - initial_val);
    settling_time = NaN;
    for k = 1:length(A_array)
        if all(abs(A_array(k:end) - final_val) <= band)
            settling_time = time_array(k);
            break;
        end
    end

    %% Package
    metrics.initial_val   = initial_val;
    metrics.final_val     = final_val;
    metrics.rise_time     = rise_time;
    metrics.peak_time     = peak_time;
    metrics.peak_val      = peak_val;
    metrics.overshoot     = overshoot;
    metrics.settling_time = settling_time;
end

function displayMetrics(metrics)
    fprintf('Initial AOA:              %.4f\n', metrics.initial_val);
    fprintf('Final AOA:                %.4f\n', metrics.final_val);
    fprintf('AOA Rise Time (10‑90%%):   %.4f s\n', metrics.rise_time);
    fprintf('Peak Time (s):            %.4f\n', metrics.peak_time);
    fprintf('Peak Angle‑of‑Attack:     %.4f deg\n', metrics.peak_val);
    fprintf('Overshoot:                %.2f%%\n', metrics.overshoot);
    fprintf('Settling Time:            %.4f s\n', metrics.settling_time);
end