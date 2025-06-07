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

%---

%% nm_contour: bubble-chart visualization of puck combos
% This script assumes you've already run main.m so that the following variables exist in the workspace:
%   data_temps  (1×nT vector of temperatures)
%   data_winds  (1×nW vector of wind speeds)
%   data_puckCount (nP×nT×nW array of puck counts)
%   pucks_g     (1×nP vector of puck sizes in grams)

% ensure pucks_g and nP are defined
if ~exist('pucks_g','var')
    error('Variable ''pucks_g'' not found. Run main.m first.');
end
nP = numel(pucks_g);

% mesh for grid points (nT×nW each)
[Wgrid, Tgrid] = meshgrid(data_winds, data_temps);

% offsets to spread bubbles around each cell
offsetRange = 0.30;  % max offset in axes units
offsets = linspace(-offsetRange, +offsetRange, nP);

% pick distinct colors for each puck size
colors = lines(nP);

% create figure
figure('Color','w','Position',[100,100,900,700]);
hold on;
for i = 1:nP
    % flatten into vectors
    X = Wgrid(:) + offsets(i);
    Y = Tgrid(:);
    CNT = reshape(data_puckCount(i,:,:), [], 1);
    % marker area: scale so zero → invisible, others visible
    areaScale = 200;  % try 200 for more visibility
    S = areaScale * CNT;
    idxNonzero = CNT > 0;
    scatter(X(idxNonzero), Y(idxNonzero), S(idxNonzero), 'o', ...
            'MarkerFaceColor', colors(i,:), ...
            'MarkerEdgeColor','k', ...
            'MarkerFaceAlpha',0.7, ...
            'LineWidth',0.5);
end

% styling
grid on;
set(gca, ...
    'YDir','normal', ...
    'XTick', data_winds, ...
    'YTick', data_temps, ...
    'FontSize',14);
xlabel('Wind Speed (mph)','FontSize',16,'FontWeight','bold');
ylabel('Temperature (°C)','FontSize',16,'FontWeight','bold');
title('Bubble Chart of Puck Counts per Condition','FontSize',18,'FontWeight','bold');

% add legend outside
legendLabels = cellstr(string(pucks_g) + ' g');
legend(legendLabels, 'Location','eastoutside', 'Box','off');

hold off;
