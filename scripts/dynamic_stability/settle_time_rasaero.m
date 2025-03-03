%% Clear Workspace and Close Figures
clear; close all; clc;

%% Constants and Unit Conversions
ft_to_m       = 0.3048;          % Feet to meters
lbft2_to_kgm2 = 1.35581795;       % lb-ft² to kg-m²
oz_to_kg      = 0.0283495;        % Ounces to kilograms
in_to_m       = 0.0254;           % Inches to meters
in2_to_m2     = 0.00064516;       % Square inches to square meters

%% File Paths and Analysis Parameters
OTIS = 'C:\Users\kyle1\Downloads\Flight Test.CSV';
OMEN = 'C:\Users\kyle1\Downloads\Kyle_wind_tunnel_OMEN.CSV';

% Start times (different for each dataset)
flightTestStart = 0.74;   % Flight Test start time
windTunnelStart = 1.1;    % Wind Tunnel start time

% Define analysis window duration (seconds)
analysisDuration = 4.05;  % For example, using similar duration for both datasets

%% Process the Data Files
[time_flight, A_flight, metrics_flight] = processData(OTIS, flightTestStart, analysisDuration);
[time_wind, A_wind, metrics_wind] = processData(OMEN, windTunnelStart, analysisDuration);

%% Tiled Plot of Angle-of-Attack (AOA) Data with Linked Axes
figure;
tiledLayout = tiledlayout(1,2, 'TileSpacing', 'Compact');

% Flight Test Plot
ax1 = nexttile;
plot(time_flight, A_flight, 'g', 'LineWidth', 1.5);
hold on;
% Plot tolerance band lines for Flight Test
y_upper_flight = metrics_flight.final_val + metrics_flight.band;
y_lower_flight = metrics_flight.final_val - metrics_flight.band;
plot([time_flight(1) time_flight(end)], [y_upper_flight y_upper_flight], 'r--', 'LineWidth', 1);
plot([time_flight(1) time_flight(end)], [y_lower_flight y_lower_flight], 'r--', 'LineWidth', 1);
xlabel('Time (s)');
ylabel('AOA (deg)');
title('OTIS AOA');
grid on;

% Wind Tunnel Plot
ax2 = nexttile;
plot(time_wind, A_wind, 'b', 'LineWidth', 1.5);
hold on;
% Plot tolerance band lines for Wind Tunnel
y_upper_wind = metrics_wind.final_val + metrics_wind.band;
y_lower_wind = metrics_wind.final_val - metrics_wind.band;
plot([time_wind(1) time_wind(end)], [y_upper_wind y_upper_wind], 'r--', 'LineWidth', 1);
plot([time_wind(1) time_wind(end)], [y_lower_wind y_lower_wind], 'r--', 'LineWidth', 1);
xlabel('Time (s)');
ylabel('AOA (deg)');
title('OMEN AOA');
grid on;

% Link the axes of the two subplots to ensure the same scale
linkaxes([ax1, ax2], 'xy');

%% Display a Comparison Report of the Metrics
fprintf('\n=== Response Metrics Comparison ===\n');

fprintf('\n--- OTIS ---\n');
displayMetrics(metrics_flight);

fprintf('\n--- OMEN ---\n');
displayMetrics(metrics_wind);

%% --- Local Functions ---

function [time_array, A_array, metrics] = processData(filePath, startTime, duration)
    % Reads the CSV file, extracts time and angle-of-attack data, limits the 
    % data to the analysis window [startTime, startTime+duration], and computes metrics.
    
    % Read data from CSV
    data = readtable(filePath);
    
    % Extract time and AOA columns (assumes the CSV contains these headers)
    time_array = data.Time_sec_;
    A_array = data.AngleOfAttack_deg_;
    
    % Round time values for consistency
    time_array = round(time_array, 3);
    
    % Limit data to the desired time interval
    valid_indices = (time_array >= startTime) & (time_array <= (startTime + duration));
    time_array = time_array(valid_indices);
    A_array = A_array(valid_indices);
    
    % Compute response metrics
    metrics = computeMetrics(time_array, A_array);
end

function metrics = computeMetrics(time_array, A_array)
    % Computes response metrics (initial value, final value, rise time, peak value/time,
    % overshoot, undershoot, settling time) based on the provided time and AOA arrays.
    
    % Initial and Final values
    initial_val = A_array(1);
    n_final = max(1, round(0.1 * length(A_array)));  % average last 10% for smoothing
    final_val = mean(A_array(end - n_final + 1 : end));
    
    % Compute 10% and 90% levels for rise time determination
    if final_val >= initial_val
        level10 = initial_val + 0.1 * (final_val - initial_val);
        level90 = initial_val + 0.9 * (final_val - initial_val);
        idx10 = find(A_array >= level10, 1, 'first');
        idx90 = find(A_array >= level90, 1, 'first');
    else
        level10 = initial_val - 0.1 * (initial_val - final_val);
        level90 = initial_val - 0.9 * (initial_val - final_val);
        idx10 = find(A_array <= level10, 1, 'first');
        idx90 = find(A_array <= level90, 1, 'first');
    end
    
    if ~isempty(idx10) && ~isempty(idx90)
        rise_time = time_array(idx90) - time_array(idx10);
    else
        rise_time = NaN;
    end
    
    % Determine Peak Value and Time
    if final_val >= initial_val
        [peak_val, idx_peak] = max(A_array);
    else
        [peak_val, idx_peak] = min(A_array);
    end
    peak_time = time_array(idx_peak);
    
    % Calculate Overshoot (percentage)
    if final_val >= initial_val
        if peak_val > final_val
            overshoot = (peak_val - final_val) / (final_val - initial_val) * 100;
        else
            overshoot = 0;
        end
    else
        if peak_val < final_val
            overshoot = (final_val - peak_val) / (initial_val - final_val) * 100;
        else
            overshoot = 0;
        end
    end
    
    % Calculate Undershoot (percentage)
    if final_val >= initial_val
        min_val = min(A_array);
        if min_val < final_val
            undershoot = (final_val - min_val) / (final_val - initial_val) * 100;
        else
            undershoot = 0;
        end
    else
        max_val = max(A_array);
        if max_val > final_val
            undershoot = (max_val - final_val) / (initial_val - final_val) * 100;
        else
            undershoot = 0;
        end
    end
    
    % Compute Settling Time: time after which the response remains within a tolerance band
    tolerance = 0.02;  % 2% tolerance (can be adjusted)
    step_height = abs(final_val - initial_val);
    band = tolerance * step_height;
    settling_time = NaN;
    for k = 1:length(A_array)
        if all(abs(A_array(k:end) - final_val) <= band)
            settling_time = time_array(k);
            break;
        end
    end
    
    % Pack computed metrics into a structure
    metrics.initial_val   = initial_val;
    metrics.final_val     = final_val;
    metrics.rise_time     = rise_time;
    metrics.peak_time     = peak_time;
    metrics.peak_val      = peak_val;
    metrics.overshoot     = overshoot;
    metrics.undershoot    = undershoot;
    metrics.settling_time = settling_time;
    metrics.band          = band;  % include band for plotting tolerance lines
end

function displayMetrics(metrics)
    % Prints the response metrics to the console in a readable format.
    fprintf('Initial Value: %.4f\n', metrics.initial_val);
    fprintf('Final Value: %.4f\n', metrics.final_val);
    fprintf('Rise Time (10%% to 90%%): %.4f s\n', metrics.rise_time);
    fprintf('Peak Time: %.4f s\n', metrics.peak_time);
    fprintf('Peak Value: %.4f\n', metrics.peak_val);
    fprintf('Overshoot: %.2f%%\n', metrics.overshoot);
    fprintf('Undershoot: %.2f%%\n', metrics.undershoot);
    fprintf('Settling Time: %.4f s\n', metrics.settling_time);
end
