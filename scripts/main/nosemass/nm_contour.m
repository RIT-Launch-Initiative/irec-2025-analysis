% Compute contour levels at fixed ste
minVal = min(data_nmass(:));
maxVal = max(data_nmass(:));

levs = floor(minVal/step)*step : step : ceil(maxVal/step)*step;

% Plot filled contours
figure;

contourf(data_winds, data_temps, data_nmass, levs, ...
         'LineColor','none', ...
         'FaceAlpha', 0.85);
xlabel('Wind Speed (mph)','FontSize',24);
ylabel('Temperature (°C)','FontSize',24);
hold on;

% Plot contour lines
[C, hC] = contour(data_winds, data_temps, data_nmass, levs, ...
                  'LineWidth', 1.5, ...   % thicker lines
                  'LineColor', 'k');
clabel(C, hC, ...
       'FontSize', 18, ...
       'FontWeight', 'bold', ...
       'Color', 'k');

% Flip colormap: white (light) to gray (heavy)
nColors = 256;
minGray = 0.25;
graymap = linspace(1, minGray, nColors)';
colormap(repmat(graymap, 1, 3));

% Overall font size for axes ticks, titles, etc.
set(gca, 'FontSize', 20);

hold off;
