clear; close all;

addpath(genpath("C:\\lmatlib"))

% Load the OTIS rocket file
otis_path = "C:\\irec-2025-analysis\\IREC_2025_M6000ST-0.ork";
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end

% Initialize OpenRocket
otis = openrocket(otis_path);
sim = otis.sims("MATLAB");
opts = sim.getOptions();

% Example configuration
opts.setWindSpeedAverage(15);        % For demonstration, 0 m/s
opts.setWindTurbulenceIntensity(10)
opts.setLaunchTemperature(25 + 273.15);  % 25°C
opts.setLaunchAltitude(1828);       % ~6000 ft

% Run single simulation
iSim = openrocket.simulate(sim, outputs="ALL");

% Retrieve simulation data
data = openrocket.get_data(sim);

figure;
plot3(data.("Position East of launch")*3.28084, ...
      data.("Position North of launch")*3.28084, ...
      data.Altitude*3.28084, 'LineWidth', 1.5);
grid on;

view(3);
xlabel('Position East (ft)');
ylabel('Position North (ft)');
zlabel('Altitude (ft)');
title('3D Trajectory (15mph,10%turb))');

