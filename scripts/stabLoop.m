clear; close all;

addpath(genpath("C:\irec-2025-analysis\lmatlib"))

% Load the OTIS rocket file
otis_path = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end

% Initialize OpenRocket
otis = openrocket(otis_path);
sim = otis.sims("MATLAB");
opts = sim.getOptions();

% Fixed configuration parameters (set your desired values)
fixedWindSpeed = 15;     % m/s (single wind speed)
fixedTemperature = 25;   % °C (single temperature)
numTrials = 2;         % Number of simulation runs

% Configure constant parameters
opts.setWindSpeedAverage(fixedWindSpeed);
opts.setLaunchTemperature(fixedTemperature);
opts.setWindTurbulenceIntensity(10);    % 10% turbulence intensity
opts.setWindSpeedDeviation(5);          % 5 m/s wind speed deviation

% Preallocate stability data storage
stabilityMargins = zeros(numTrials, 1);
validRuns = 0;

% Run multiple trials
for i = 1:numTrials
    try
        % Run simulation with new wind randomness
        iSim = openrocket.simulate(sim, outputs="ALL");
        data = openrocket.get_data(sim);
        
        % Store stability margin at 1.26 seconds (row 127)
        stabilityMargins(i) = data{127, 'Stability margin'};
        validRuns = validRuns + 1;
    catch
        % Handle potential simulation failures
        stabilityMargins(i) = NaN;
    end
end

% Clean data (remove failed runs)
stabilityMargins = stabilityMargins(~isnan(stabilityMargins));

% Create distribution plot
figure;
hold on;

% Histogram with probability normalization
histogram(stabilityMargins, 'Normalization', 'pdf', ...
         'FaceColor', [0.2 0.4 0.8], 'EdgeColor', 'none', ...
         'NumBins', 25, 'DisplayName', 'Histogram');


% Add vertical line at mean
yLimits = ylim;
line([mean(stabilityMargins) mean(stabilityMargins)], yLimits, ...
     'Color', [0.3 0.7 0.3], 'LineWidth', 1.5, 'LineStyle', '--', ...
     'DisplayName', 'Mean');

hold off;

% Formatting
title(sprintf('Stability Margin Distribution (n = %d runs)\n%d m/s wind, %d°C', ...
    validRuns, fixedWindSpeed, fixedTemperature));
xlabel('Stability Margin (cal)');
ylabel('Probability Density');
legend('Location', 'northwest');
grid on;
box on;

% Display summary statistics
fprintf('Stability margin statistics (%d valid runs):\n', validRuns);
fprintf('Mean: %.3f cal\n', mean(stabilityMargins));
fprintf('Standard Deviation: %.3f cal\n', std(stabilityMargins));
fprintf('Minimum: %.3f cal\n', min(stabilityMargins));
fprintf('Maximum: %.3f cal\n', max(stabilityMargins));