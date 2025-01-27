clear;

addpath(genpath("C:\lmatlib"))

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
opts.setWindTurbulenceIntensity(0)
temperature = 10:1:46;
temperatureF = (temperature * 9/5) + 32; % Convert to Fahrenheit
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
bars = bar(temperatureF, cellfun(@(altData) max(altData), altitudeData), 'FaceColor', 'flat');

% Color bars based on temperature
for i = 1:nTemps
    bars.CData(i, :) = [temperature(i) / max(temperature), 0.5, 1 - temperature(i) / max(temperature)];
end

% Plot formatting
xlabel('Temperature (°F)');
ylabel('Max Altitude (ft)');
title(sprintf('Max Altitude vs Temperature (Wind Speed = 15mph)'));
grid on;
