% Visualization
figure;
plot(temperatureF, maxAltitudes, 'o-', 'MarkerFaceColor', 'b', 'LineWidth', 2);
xlabel('Temperature (°F)');
ylabel('Maximum Altitude (ft)');
title(sprintf('Maximum Altitude vs Launch Temperature (Wind Speed = 15 mph)'));
grid on;
box on;

% Remove scientific notation from y-axis
ax = gca;
ax.YAxis.Exponent = 0;
ytickformat('%.0f');  % Format y-ticks as whole numbers

ylim([8750 11250]);

%lines for target
yline(11000, 'r--', '+10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
yline(10000, 'g--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
yline(9000, 'r--', '-10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');