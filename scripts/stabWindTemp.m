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

% Configuration parameters
windSpeeds = 0:2.5:30;
temperature = 10:2.5:46;  % Now handles any number of temperatures
nSims = numel(windSpeeds);
nTemps = numel(temperature);

% Preallocate master data matrix
masterData = zeros(nSims, nTemps + 1);  % +1 for wind speed column
masterData(:,1) = windSpeeds';  % Transpose to column vector

% Simulation loop
for iTemp = 1:nTemps
    tSet = temperature(iTemp);
    stabOffRod = zeros(nSims, 1);  % Column vector for proper assignment
    
    for jWind = 1:nSims
        % Configure simulation
        opts.setWindSpeedAverage(windSpeeds(jWind));
        opts.setLaunchTemperature(tSet);
        
        % Run simulation and get data
        iSim = openrocket.simulate(sim, outputs="ALL");
        data = openrocket.get_data(sim);
        
        % Store stability margin at 0.26 seconds
        stabOffRod(jWind) = data{126, 'Stability margin'};
    end
    
    % Store results in corresponding temperature column
    masterData(:, iTemp + 1) = stabOffRod;
end

% Visualization
figure;
colors = parula(nTemps);  % Create unique colors for each temperature
legendEntries = cell(nTemps, 1);

for iTemp = 1:nTemps
    scatter(masterData(:,1), masterData(:,iTemp+1), ...
            'filled', ...
            'MarkerFaceColor', colors(iTemp,:), ...
            'DisplayName', sprintf('%0.1f°C', temperature(iTemp)));
    hold on;
end

hold off;

% Plot formatting
xlabel('Wind Speed (m/s)');
ylabel('Stability Margin (cal)');
title(sprintf('Stability vs Wind Speed (Temperatures %0.1f°C to %0.1f°C)', ...
    min(temperature), max(temperature)));
legend('Location', 'best', 'NumColumns', 2);
grid on;
