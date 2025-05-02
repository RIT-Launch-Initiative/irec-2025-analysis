close all;
clear all;

%--------------- User parameters ---------------
step = 0.1;   % contour interval (kg)
%-----------------------------------------------

% assume windVals_mph, tempVals_C, massChart_kg are already in workspace
data_temps = 20:1:35;
data_winds = 4:1:10;

nsims = numel(data_temps)*numel(data_winds);

data_nmass = zeros(1,nsims);

wbar = waitbar(0, sprintf('Running %d sims...', nsims));

sim_num = 0;
for i = 1:numel(data_temps)
    for k = 1:numel(data_winds)
        sim_num = sim_num + 1;
        waitbar(sim_num/nsims, wbar, ...
            sprintf('Deg: %.1f, Wind Speed: %.1f, Sim %d / %d', data_temps(i), data_winds(k), sim_num, nsims));
        data_nmass(k,i) = req_nosemass(data_temps(i), data_winds(k));
    end
end

close(wbar);


% Compute contour levels at fixed steps
minVal = min(data_nmass);
maxVal = max(data_nmass);
levs = floor(minVal/step)*step : step : ceil(maxVal/step)*step;

% Plot filled contours
figure;

contourf(data_winds, data_temps, data_nmass', levs, ...
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
