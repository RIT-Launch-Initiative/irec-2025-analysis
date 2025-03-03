clear; clc;

% Rocket parameters
post_boost_mass = 24.3; % Mass of the rocket in kg
drogue_deploy_velocity_open_rocket = 38; % Initial velocity at deployment in m/s taken from open rocket total velocity


chute_diameter = 2.44;
chute_drag_area = pi * (chute_diameter / 2)^2; % Drag area for parachute in m^2
chute_drag_Cd = 2.2;
chute_deployment_alitutde_air_density = 1.17; % Air density in kg/m^3 at 10000 ft

streamer_drag_area = 17.4;
streamer_drag_Cd = 0.05;
streamer_deployment_alitutde_air_density = 0.907; % Air density in kg/m^3 at 10000 ft


% Environmental parameters
g = 9.81; % Acceleration due to gravity in m/s^2


% maximum drag force when fully deployed
drogue_max_drag_force = 0.5 * streamer_deployment_alitutde_air_density * drogue_deploy_velocity_open_rocket^2 * streamer_drag_Cd * streamer_drag_area;

% decent rate
% drogue_decent_rate = sqrt((2*post_boost_mass)/(streamer_drag_Cd*streamer_deployment_alitutde_air_density*streamer_drag_area));
drogue_decent_rate = 23; %m/s from open rocket

% Display results for drogue
fprintf('Snatch Force Calculation for drogue streamer\n');
fprintf('-------------------------------------------------\n');
fprintf('Mass of rocket: %.2f kg\n', post_boost_mass);
fprintf('Initial velocity at drogue deployment: %.2f m/s\n', drogue_deploy_velocity_open_rocket);
fprintf('Streamer device area: %.2f m^2\n', streamer_drag_area);
fprintf('Streamer coefficient (Cd): %.2f\n', streamer_drag_Cd);
fprintf('Streamer altitude air density: %.3f kg/m^3\n', streamer_deployment_alitutde_air_density);
fprintf('Maximum drogue snatch force: %.2f N\n', drogue_max_drag_force);
fprintf('Drogue descent rate: %.2f m/s\n\n', drogue_decent_rate);

% maximum drag force when fully deployed
main_max_drag_force = 0.5 * chute_deployment_alitutde_air_density * drogue_decent_rate^2 * chute_drag_Cd * chute_drag_area;

% decent rate
%main_descent_rate = sqrt((2*post_boost_mass)/(chute_drag_Cd*chute_deployment_alitutde_air_density*chute_drag_area));
main_descent_rate = 8; %m/s taken from open rocket simulation

% Display results for drogue
fprintf('Snatch Force Calculation for main chute\n');
fprintf('-------------------------------------------------\n');
fprintf('Mass of rocket: %.2f kg\n', post_boost_mass);
fprintf('Initial velocity at main deployment: %.2f m/s\n', drogue_decent_rate);
fprintf('Chute area: %.2f m^2\n', chute_drag_area);
fprintf('Chute coefficient (Cd): %.2f\n', chute_drag_Cd);
fprintf('Chute altitude air density: %.3f kg/m^3\n', chute_deployment_alitutde_air_density);
fprintf('Maximum main snatch force: %.2f N\n', main_max_drag_force);
fprintf('Main descent rate: %.2f m/s\n', main_descent_rate);