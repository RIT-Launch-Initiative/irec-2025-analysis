clear;

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
windSpeed = 6.7;  % Fixed wind speed at 15mph
temperature = 10:5:50;
nTemps = numel(temperature);

% Preallocate cell arrays to store time and altitude data
timeData = cell(nTemps, 1);
altitudeData = cell(nTemps, 1);

% Simulation loop
for iTemp = 1:nTemps
    tSet = temperature(iTemp);
    
    % Configure simulation
    opts.setWindSpeedAverage(windSpeed);
    opts.setLaunchTemperature(tSet+273.15);
    opts.setLaunchAltitude(1828)

    
    % Run simulation and get data
    iSim = openrocket.simulate(sim, outputs="ALL");
    data = openrocket.get_data(sim);
    
    % Store time and altitude data
    timeData{iTemp} = data.Time;
    altitudeData{iTemp} = data.Altitude * 3.28084;  % Conversion to feet
end

% Visualization
figure;
colors = parula(nTemps);  % Create unique colors for each temperature
legendEntries = cell(nTemps, 1);

for iTemp = 1:nTemps
    plot(timeData{iTemp}, altitudeData{iTemp}, ...
         'Color', colors(iTemp,:), ...
         'DisplayName', sprintf('%0.1f°C', temperature(iTemp)));
    hold on;
end

hold off;

% Plot formatting
xlabel('Time (s)');
ylabel('Altitude (ft)'); 
title(sprintf('Altitude vs Time at Different Temperatures (Wind Speed = 15mph)'));
legend('Location', 'best', 'NumColumns', 2);
ylim([9500,10500]);
grid on;