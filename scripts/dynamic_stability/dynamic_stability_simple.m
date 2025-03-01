clear
close all;
% Constants and Unit Conversions
ft_to_m = 0.3048;          % Feet to meters
lbft2_to_kgm2 = 1.35581795; % lb-ft² to kg-m²
oz_to_kg = 0.0283495;      % Ounces to kilograms
in_to_m = 0.0254;          % Inches to meters
in2_to_m2 = 0.00064516;    % Square inches to square meters


ork_file_path = "C:\Users\kyle1\Downloads\IREC2023 V21(5_9_23) (1).ork";
addpath(genpath("C:\lmatlib\"));
otis = openrocket(ork_file_path);


sim = otis.sims("Spaceport America");

% opts = sim.getOptions;
opts.setTimeStep(0.0001)
opts.setWindSpeedAverage(0)
opts.setWindTurbulenceIntensity(0)
openrocket.simulate(sim);
OTIS = openrocket.get_data(sim);

time_array = OTIS.("Time");

figure;
plot_openrocket(OTIS, "Stability margin", "Angle of attack", ...
    start_ev = "LAUNCHROD", end_ev = "APOGEE", labels = ["LAUNCHROD", "BURNOUT"]);



% Convert duration to seconds and round to 3 decimal places
time_array = round(seconds(time_array), 3);

% Extract angle of attack data from the dataset
A_array = rad2deg(OTIS.("Angle of attack"));

% Limit the scope of angle of attack data (e.g., between -2 and 2 degrees)
% Also limit the time_array accordingly
valid_indices =  (time_array >= 0.5) & (time_array <= 5);

% Apply valid_indices to both arrays
A_array = A_array(valid_indices);
time_array = time_array(valid_indices);


% Assuming A0 is a reference value for the angle of attack
A0 = A_array(1,1);

% Calculate the logarithmic decrement ln(A/A0) for each time step
ln_A_A0_array = round(log(A_array / A0), 3);

% Use linear fitting to estimate -gamma from the plot
p = polyfit(time_array, ln_A_A0_array, 1); % Linear fit: y = mx + c, p(1) is slope
negative_gamma = p(1); % Slope of the line is -gamma
gamma = -negative_gamma; % Extract gamma from -gamma
y = gamma * time_array;

% Create a single figure with three subplots
figure;
tiledlayout(2,1);

% Plot ln(A/A0) Over Time
nexttile;
plot(time_array, ln_A_A0_array, 'b', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('ln(\alpha/\alpha_0)');
title('Plot of ln(\alpha/\alpha_0) Over Time to Determine -\gamma');
grid on;

% Plot Angle of Attack Over Time
nexttile;
plot(time_array, A_array, 'g', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Angle of Attack (\alpha) [degrees]');
title('Plot of Angle of Attack (\alpha) Over Time');
grid on;

% Display Final Results
disp('Damping Analysis Results:');
fprintf('Damping Ratio (gamma): %.4f\n', gamma);

% Define the tolerance for settling (2% in this example)
tolerance = 0.05;  % or choose another value, e.g., 0.05 for 5%

% Calculate settling time based on the exponential decay model
t_settle = -log(tolerance) / gamma;

% Display the settling time result
fprintf('Estimated Settling Time: %.4f seconds\n', t_settle);


