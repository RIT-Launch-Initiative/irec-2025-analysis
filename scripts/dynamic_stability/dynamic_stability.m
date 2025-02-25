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
valid_indices = (A_array >= -2 & A_array <= 2) & (time_array >= 0.766) & (time_array <= 2.706);

% Apply valid_indices to both arrays
A_array = A_array(valid_indices);
time_array = time_array(valid_indices);

% Convert to double and round to 3 decimal places
A_array = round(double(A_array), 3);

% Check if A_array is not empty
if ~isempty(A_array)
    % Initial angle of attack at time t=0
    A0 = double(A_array(1));
else
    error('No valid angle of attack data in the specified range.');
end

% Calculate the logarithmic decrement ln(A/A0) for each time step
ln_A_A0_array = round(log(A_array / A0), 3);

% Create a figure for all four plots on one page
figure;

% Plot ln(A/A0) Over Time to find -gamma
subplot(4, 1, 1);
plot(time_array, ln_A_A0_array, 'b', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('ln(\alpha/\alpha_0)');
title('Plot of ln(\alpha/\alpha_0) Over Time to Determine -\gamma');
grid on;

% Use linear fitting to estimate -gamma from the plot
p = polyfit(time_array, ln_A_A0_array, 1); % Linear fit: y = mx + c, p(1) is slope
negative_gamma = p(1); % Slope of the line is -gamma
gamma = -negative_gamma; % Extract gamma from -gamma

% Plot Gamma Over Time
subplot(4, 1, 2);
plot(time_array, repmat(gamma, size(time_array)), 'r', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Damping Ratio (\gamma)');
title('Plot of Damping Ratio (\gamma) Over Time');
grid on;

% Plot Angle of Attack Over Time
subplot(4, 1, 3);
plot(time_array, A_array, 'g', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Angle of Attack (\alpha) [degrees]');
title('Plot of Angle of Attack (\alpha) Over Time');
grid on;

% Calculate Gamma for Different Time Intervals (Blocks of specified duration)
start_time = min(time_array);
end_time = max(time_array);
block_duration = 2.5; % Adjust block duration to be smaller than total time range
gamma_values = [];
block_labels = [];

% Loop over the time range in steps of block_duration
t = start_time;
while t < end_time
    % Adjust block end time to not exceed end_time
    block_end_time = min(t + block_duration, end_time);

    % Extract time and angle of attack data for the current block
    block_indices = (time_array >= t) & (time_array < block_end_time);
    block_time_array = time_array(block_indices);
    block_A_array = A_array(block_indices);

    % Check if there is enough data in the block
    if length(block_time_array) > 1
        % Calculate the logarithmic decrement for the block
        block_A0 = block_A_array(1);
        block_ln_A_A0_array = log(block_A_array / block_A0);

        % Use linear fitting to estimate -gamma for the block
        p_block = polyfit(block_time_array, block_ln_A_A0_array, 1); % Linear fit: y = mx + c, p(1) is slope
        negative_gamma_block = p_block(1); % Slope of the line is -gamma
        gamma_block = -negative_gamma_block; % Extract gamma from -gamma

        % Store the gamma value and label for the block
        gamma_values = [gamma_values; gamma_block];
        block_labels = [block_labels; string(sprintf('Block %.1f-%.1f s', t, block_end_time))];
    end

    % Move to the next block
    t = t + block_duration;
end

% Plot Gamma vs. Time Blocks
subplot(4, 1, 4);
bar(categorical(block_labels), gamma_values, 'FaceColor', 'm');
xlabel('Time Blocks');
ylabel('Damping Ratio (\gamma)');
title('Damping Ratio (\gamma) for Different Time Intervals');
grid on;

% Display Final Results
disp('Damping Analysis Results:');
fprintf('Damping Ratio (gamma): %.4f\n', gamma);
