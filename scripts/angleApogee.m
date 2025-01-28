clear;
addpath(genpath("C:\lmatlib"));

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
windSpeed = 6.7;  % 6.7 m/s = 15 mph
opts.setWindTurbulenceIntensity(0);
minAngle = 90-86;
maxAngle = 90-84;
angleStep = 0.1;
launchAngles = (deg2rad(minAngle)):(deg2rad(angleStep)):(deg2rad(maxAngle));
nAngles = numel(launchAngles);

% Preallocate array for maximum altitudes
maxAltitudes = zeros(nAngles, 1);

% Simulation loop
for iAngle = 1:nAngles
    angleSet = launchAngles(iAngle);
    
    % Configure simulation
    opts.setWindSpeedAverage(windSpeed);
    opts.setLaunchTemperature(36 + 273.15);  % Convert Celsius to Kelvin
    opts.setLaunchRodAngle(angleSet)
    opts.setLaunchAltitude(1828);% Launch altitude in meters
    
    % Run simulation and get data
    iSim = openrocket.simulate(sim, outputs="ALL");
    data = openrocket.get_data(sim);
    
    % Store maximum altitude (convert meters to feet)
    maxAltitudes(iAngle) = max(data.Altitude) * 3.28084;
end

% Visualization
figure;
plot((rad2deg(launchAngles)), maxAltitudes, 'o-', 'MarkerFaceColor', 'b', 'LineWidth', 2);
xlabel('Launch Angle (°)');
ylabel('Maximum Altitude (ft)');
title(sprintf('Maximum Altitude vs Launch Angle (Wind Speed = 15 mph)'));
grid on;
box on;

ylim([8750 11250])
yline(11000, 'r--', '+10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
yline(10000, 'g--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
yline(9000, 'r--', '-10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');

fontsize(16,"points");

% Remove scientific notation from y-axis
ax = gca;
ax.YAxis.Exponent = 0;
ytickformat('%.0f');  % Format y-ticks as whole numbers

