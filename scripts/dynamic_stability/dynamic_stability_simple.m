% Constants and Unit Conversions
ft_to_m = 0.3048;          % Feet to meters
lbft2_to_kgm2 = 1.35581795; % lb-ft² to kg-m²
oz_to_kg = 0.0283495;      % Ounces to kilograms
in_to_m = 0.0254;          % Inches to meters
in2_to_m2 = 0.00064516;    % Square inches to square meters

% Initialize results arrays as floats
% These arrays will store the calculated values for each time step

% Assuming 'OTIS' is a table or dataset that contains 'Time' and 'Angle of attack' columns
% Extract time data from the dataset
time_array = OTIS.("Time");

% Convert duration to seconds and round to 3 decimal places
time_array = round(seconds(time_array), 3);

% Extract angle of attack data from the dataset
A_array = OTIS.("Angle of attack");

% Limit the scope of angle of attack data (e.g., between -2 and 2 degrees)
% Also limit the time_array accordingly
valid_indices = (A_array >= -2 & A_array <= 5) & (time_array >= 1.316) & (time_array <= 2.706);

% Apply valid_indices to both arrays
A_array = A_array(valid_indices);
time_array = time_array(valid_indices);

% Convert to double and round to 3 decimal places
A_array = round(double(A_array), 3);

% Assuming A0 is a reference value for the angle of attack
A0 = .796; % Replace with the appropriate value

% Calculate the logarithmic decrement ln(A/A0) for each time step
ln_A_A0_array = round(log(A_array / A0), 3);

% Use linear fitting to estimate -gamma from the plot
p = polyfit(time_array, ln_A_A0_array, 1); % Linear fit: y = mx + c, p(1) is slope
negative_gamma = p(1); % Slope of the line is -gamma
gamma = -negative_gamma; % Extract gamma from -gamma
y = gamma * time_array;

% Create a single figure with three subplots
figure;

% Plot ln(A/A0) Over Time
subplot(3, 1, 1); % 3 rows, 1 column, 1st subplot
plot(time_array, ln_A_A0_array, 'b', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('ln(\alpha/\alpha_0)');
title('Plot of ln(\alpha/\alpha_0) Over Time to Determine -\gamma');
grid on;

% Plot Gamma Over Time
subplot(3, 1, 2); % 3 rows, 1 column, 2nd subplot
plot(time_array, -y, 'r', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Damping Ratio (\gamma)');
title('Plot of Damping Ratio (\gamma) Over Time');
grid on;

% Plot Angle of Attack Over Time
subplot(3, 1, 3); % 3 rows, 1 column, 3rd subplot
plot(time_array, A_array, 'g', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Angle of Attack (\alpha) [degrees]');
title('Plot of Angle of Attack (\alpha) Over Time');
grid on;

% Display Final Results
disp('Damping Analysis Results:');
fprintf('Damping Ratio (gamma): %.4f\n', gamma);
