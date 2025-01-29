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

% Set config
nSims = 30;
turbIntesity = 1;
opts.setWindTurbulenceIntensity(0.15);
opts.setWindSpeedAverage(6.7);
opts.setLaunchTemperature(25 + 273.15);  % 25°C

% Run a single simulation
iSim = openrocket.simulate(sim, outputs="ALL");

% Retrieve simulation data
data = openrocket.get_data(sim);

% Convert units to feet (1 meter = 3.28084 ft)
ft = 3.28084;
x_ft = data.("Position East of launch") * ft;
y_ft = data.("Position North of launch") * ft;
z_ft = data.Altitude * ft;

% Create one figure for 3D curve with overlaid 2D projections
figure('Name','Rocket Trajectory with 2D projections');

% 3D Trajectory
plot3(x_ft, y_ft, z_ft, 'LineWidth', 1.5, 'DisplayName','3D Trajectory');
hold on;
grid on;
axis padded;
fontsize(16,"points")


zlim([0 12000])
xlim([0 inf]) 
ylim([0 inf])

% XY projection (Z=0)
plot3(x_ft, y_ft, zeros(size(z_ft)), '--', 'LineWidth', 1.5, 'DisplayName','XY Projection');

% YZ projection (X=0)
plot3(zeros(size(x_ft)), y_ft, z_ft, '--', 'LineWidth', 1.5, 'DisplayName','YZ Projection');

% XZ projection (Y=0)
plot3(x_ft, zeros(size(y_ft)), z_ft, '--', 'LineWidth', 1.5, 'DisplayName','XZ Projection');

xlabel('East (ft)');
ylabel('North (ft)');
zlabel('Altitude (ft)');
[apogeeAltitude, apogeeIndex] = max(z_ft); % Max altitude and its index
apogeePosition = [x_ft(apogeeIndex), y_ft(apogeeIndex), apogeeAltitude];
apogeeMarker = scatter3(apogeePosition(1), apogeePosition(2), apogeePosition(3), 100, 'r', 'filled', 'DisplayName', 'Apogee');

title('3D Trajectory with XY, YZ, and XZ Projections');
legend;
view(3);
