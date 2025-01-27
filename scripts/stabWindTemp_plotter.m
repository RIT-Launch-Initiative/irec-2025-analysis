% Convert wind speed from m/s to mph
windSpeedMph = masterData(:,1) * 2.23694;

% Convert temperature from Celsius to Fahrenheit
tempF = temperature * 9/5 + 32;

figure;
colors = parula(nTemps);  % Create unique colors for each temperature
legendEntries = cell(nTemps, 1);

for iTemp = 1:nTemps
    scatter(windSpeedMph, masterData(:, iTemp+1), ...
            'filled', ...
            'MarkerFaceColor', colors(iTemp,:), ...
            'DisplayName', sprintf('%0.1f°F', tempF(iTemp)));
    hold on;
end

% Add Go/No-Go wind speed line at 20 mph
xline(20, 'r--', 'Go/No-Go', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');

hold off;

% Plot formatting
xlabel('Wind Speed (mph)');
ylabel('Stability Margin (cal)');
title(sprintf('Stability vs Wind Speed (Temperatures %0.1f°F to %0.1f°F)', ...
    min(tempF), max(tempF)));
legend('Location', 'best', 'NumColumns', 2);
grid on;
grid minor;
