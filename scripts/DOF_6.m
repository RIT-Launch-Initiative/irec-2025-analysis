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

% Use a fixed 0.01s time step in the simulation
opts.setTimeStep(0.05)

% Run a single simulation
iSim = openrocket.simulate(sim, outputs="ALL");

% Retrieve simulation data
data = openrocket.get_data(sim);

% Convert positions to feet
ft = 3.28084;
x_ft = data.("Position East of launch") * ft;
y_ft = data.("Position North of launch") * ft;
z_ft = data.Altitude * ft;

% Also convert velocity to ft/s
velocity_fts = data.("Total velocity") * ft;

% Convert time to numeric seconds (if duration)
time_s = seconds(data.Time);

% Create figure
fig = figure('Name','Animated Rocket Trajectory');
fig.Color = [1 1 1];
hold on;
grid on;

% Plot static reference lines (XY, YZ, XZ) in dotted grey
plot3(x_ft, y_ft, zeros(size(z_ft)), ':', 'Color','r','HandleVisibility','off');
plot3(zeros(size(x_ft)), y_ft, z_ft, ':', 'Color','g','HandleVisibility','off');
plot3(x_ft, zeros(size(y_ft)), z_ft, ':', 'Color','b','HandleVisibility','off');

% Trajectory line and rocket marker
pathLine = plot3(NaN, NaN, NaN, 'b-', 'LineWidth', 1.5, 'DisplayName','Trajectory');
rocketMarker = scatter3(NaN, NaN, NaN, 60, 'filled', 'DisplayName','Rocket');

xlabel('East (ft)');
ylabel('North (ft)');
zlabel('Altitude (ft)');
title('3D Animated Trajectory - 0.01 s Time Step');

xlim([min(x_ft) max(x_ft)]);
ylim([min(y_ft) max(y_ft)]);
zlim([0 max(z_ft)*1.1]);
view(3);
axis vis3d;
legend('Location','best');

% Colormap for velocity-based color
colormap(jet);
caxis([min(velocity_fts) max(velocity_fts)]);
cb = colorbar;
cb.Label.String = 'Velocity (ft/s)';

% Time display
timeText = text(0.02, 0.95, 'Time = 0.00 s', 'Units','normalized', 'FontSize',12, 'Color','k');

% Animation loop: simply use the 0.01 s time step
nPoints = length(time_s);

for i = 1:nPoints
    % Current simulation time
    currSimTime = time_s(i);

    % Update path up to current point
    set(pathLine, 'XData', x_ft(1:i), 'YData', y_ft(1:i), 'ZData', z_ft(1:i));

    % Update rocket marker, color by velocity
    set(rocketMarker, 'XData', x_ft(i), 'YData', y_ft(i), 'ZData', z_ft(i), ...
        'CData', velocity_fts(i));

    % Update time text
    set(timeText, 'String', sprintf('Time = %.2f s', currSimTime));

    % Draw updates
    drawnow;

    % Pause for 0.01 s if not the last frame
    if i < nPoints
        pause(0.01);
    end
end
