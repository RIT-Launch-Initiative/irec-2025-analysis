% Visualization
figure;
plot((rad2deg(launchAngles)), maxAltitudes, 'o-', 'MarkerFaceColor', 'b', 'LineWidth', 2);
xlabel('Launch Angle (°)');
ylabel('Maximum Altitude (ft)');
title(sprintf('Maximum Altitude vs Launch Angle (Wind Speed = 15 mph)'));
grid on;
box on;

fontsize(16,"points")

% Remove scientific notation from y-axis
ax = gca;
ax.YAxis.Exponent = 0;
ytickformat('%.0f');  % Format y-ticks as whole numbers