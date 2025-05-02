close all;
clear all;

%--------------- User parameters ---------------
step = 0.1;   % contour interval (kg)
%-----------------------------------------------

% assume windVals_mph, tempVals_C, massChart_kg are already in workspace
data_temps = 20:1:35;
data_winds = 4:1:10;

nT = numel(data_temps);   % 16
nW = numel(data_winds);   % 7
data_nmass = zeros(nT, nW);   % 16 × 7  (rows = temps, cols = winds)


% --- create bar ---
wbar = waitbar(0, 'Running simulations...');

sim_num = 0;                       % counter for progress
nsims   = nT * nW;                 % total number of sims

for t = 1:nT
    for w = 1:nW
        sim_num = sim_num + 1;     % update progress counter
        
        % run the simulation
        data_nmass(t, w) = req_nosemass(data_temps(t), data_winds(w))
        
        % progress fraction and custom message
        frac = sim_num / nsims;
        msg  = sprintf('Temp %.1f °C | Wind %.1f mph | Sim %d of %d', ...
                       data_temps(t), data_winds(w), sim_num, nsims);
        
        % update waitbar
        waitbar(frac, wbar, msg);
    end
end

close(wbar);



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
