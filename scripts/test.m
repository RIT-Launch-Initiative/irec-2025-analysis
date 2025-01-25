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
opts.setWindSpeedAverage(0);        % For demonstration, 0 m/s
opts.setLaunchTemperature(25 + 273.15);  % 25°C
opts.setLaunchAltitude(1828);       % ~6000 ft

% Run single simulation
iSim = openrocket.simulate(sim, outputs="ALL");

% Retrieve simulation data
data = openrocket.get_data(sim);

%% 3D Plot of rocket trajectory (static)
figure;
plot3(data.("Position East of launch")*3.28084, ...
      data.("Position North of launch")*3.28084, ...
      data.Altitude*3.28084, 'LineWidth', 1.5);
grid on;
axis equal;
view(3);
xlabel('Position East (ft)');
ylabel('Position North (ft)');
zlabel('Altitude (ft)');
title('3D Trajectory (Static)');

%% Animated trajectory with velocity arrow
% Convert to feet
x_ft = data.("Position East of launch") * 3.28084;
y_ft = data.("Position North of launch") * 3.28084;
z_ft = data.Altitude * 3.28084;

% If the data set includes a variable "Vertical velocity" in m/s:
vz_m_s = data.("Vertical velocity");
vz_ft_s = vz_m_s * 3.28084;

figure('Color','w');
hold on;
grid on;
axis equal;
view(3);
xlabel('East (ft)');
ylabel('North (ft)');
zlabel('Altitude (ft)');
title('Animated Rocket Trajectory');

% Create an animated line for the rocket's path
trajLine = animatedline('Color','b','LineWidth',1.5);

% Plot an initial marker for the rocket
rocketMarker = plot3(x_ft(1), y_ft(1), z_ft(1), 'ro', 'MarkerFaceColor','r', 'MarkerSize',8);

% Create a quiver for velocity arrow (vertical only for now)
velocityScale = 0.1;
velArrow = quiver3(x_ft(1), y_ft(1), z_ft(1), 0, 0, vz_ft_s(1)*velocityScale, ...
                   'Color','r', 'MaxHeadSize',2);

for i = 1:length(x_ft)
    addpoints(trajLine, x_ft(i), y_ft(i), z_ft(i));
    set(rocketMarker, 'XData', x_ft(i), 'YData', y_ft(i), 'ZData', z_ft(i));

    % Update velocity arrow (vertical component)
    set(velArrow, 'XData', x_ft(i), 'YData', y_ft(i), 'ZData', z_ft(i), ...
        'UData', 0, 'VData', 0, 'WData', vz_ft_s(i)*velocityScale);

    drawnow;
    % pause(0.02); % adjust to control animation speed
end