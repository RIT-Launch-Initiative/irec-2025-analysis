close all;

%--------------- User parameters ---------------
step = 0.1;   % contour interval (kg)
%-----------------------------------------------

% assume windVals_mph, tempVals_C, massChart_kg are already in workspace

% Compute contour levels at fixed steps
minVal = min(massChart_kg(:));
maxVal = max(massChart_kg(:));
levs = floor(minVal/step)*step : step : ceil(maxVal/step)*step;

% Plot filled contours
figure;
contourf(windVals_mph, tempVals_C, massChart_kg, levs, ...
         'LineColor','none', ...
         'FaceAlpha', 0.85);
xlabel('Wind Speed (mph)','FontSize',24);
ylabel('Temperature (°C)','FontSize',24);
hold on;

% Plot contour lines
[C, hC] = contour(windVals_mph, tempVals_C, massChart_kg, levs, ...
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
