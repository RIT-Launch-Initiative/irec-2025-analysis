%% FIN + NOSE WEIGHT OPTIMIZATION (MKS)
%  Created by Ares Bustinza-Nguyen
%  Updated: 2/2/25
%
%  This script brute-forces a range of fin geometries & nose weights,
%  re-simulates in OpenRocket, and checks constraints. 
%  The "best" solution is the one that meets constraints and has minimal nose mass.
%
%  MODIFICATION: Show in the console each iteration pass/fail, 
%               display iteration number out of total, plus parameter values,
%               and estimate time remaining.

clear; close all;

%% 1. USER INPUTS (EDIT THESE ONLY)

% Path to your metric .ork file
ork_file_path = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
addpath(genpath("C:\lmatlib\sim"));

% Name of the OpenRocket simulation to run
sim_name = "15MPH-TEXAS-36C-(TYP)";

% Wind speed deviation (set to 0 if you want a deterministic run)
wind_speed_deviation = 0;

% Desired time step for simulation [s]
time_step = 0.075;

% Fin thickness values [m]
% Example: 0.003175 m ~ 1/8 in, 0.0047625 m ~ 3/16 in, 0.00635 m ~ 1/4 in
t_vals = [0.00635];

% Sweep, tip chord, root chord, and height scaling:
% You can scale them around the nominal values from the .ork file.
% For example, 80% to 120% in steps of 5%.
Ls_scale = 0.8:0.05:1.2;  % Sweep scale factor
h_scale  = 1;  % Height scale factor
Lt_scale = 1;
 
% For tip chord (Lt) and root chord (Lr), keep them fixed at 100%.
Lr_scale = 1.0;

% Range of nose cone adjustable weight [kg]
nose_mass_vals = 0:0.1:2;

% Constraints
FOS_min         = 1.5;   % Fin flutter factor of safety must be > 1.5
stability_rail  = 1.4;   % Stability margin off rail must be > 1.4 (example)
stability_max   = 3.90;   % Max stability during flight must be < 4.0
apogee_lower    = 2895.6; % ~9500 ft in meters
apogee_upper    = 3200.4; % ~10500 ft in meters
minSweepAngle = 20; % 

%% 2. LOAD ROCKET + KEY COMPONENTS

if ~isfile(ork_file_path)
    error("Error: .ork file not found: %s", ork_file_path);
end

% Load .ork file
otis = openrocket(ork_file_path);

% Get the chosen simulation
sim = otis.sims(sim_name);
opts = sim.getOptions;
opts.setWindSpeedDeviation(wind_speed_deviation);
opts.setTimeStep(time_step);

% Access the fin set
fins = otis.component(class="FinSet");
if ~isscalar(fins)
    error("Error: multiple or zero FinSet components found; adjust code!");
end

% Access the adjustable nose weight
NoseWeight = otis.component(name="Adjustable stability weight");
if isempty(NoseWeight)
    error("Error: No nose weight component found by that name!");
end

% Retrieve the nominal fin geometry from the .ork file
Ls_nom = fins.getSweep();      % nominal sweep (m)
Lt_nom = fins.getTipChord();   % nominal tip chord (m)
Lr_nom = fins.getRootChord();  % nominal root chord (m)
h_nom  = fins.getHeight();     % nominal fin height (m)


%% 3. SET UP THE ND-GRID (ALL CANDIDATE DESIGNS)

% Create actual numeric arrays for each parameter using the scale factors:
Ls_vals = Ls_nom * Ls_scale;
Lt_vals = Lt_nom * Lt_scale;
Lr_vals = Lr_nom * Lr_scale;
h_vals  = h_nom  * h_scale;

[t_g, Ls_g, Lt_g, Lr_g, h_g, nose_g] = ndgrid( ...
    t_vals, Ls_vals, Lt_vals, Lr_vals, h_vals, nose_mass_vals);

num_elements = numel(t_g);
fprintf("Total # of candidate designs: %d\n", num_elements);

%% 4. PRE-ALLOCATE RESULTS

% Columns of 'results':
%   1) iteration index
%   2) apogee (m)
%   3) max stability
%   4) stability off the rail
%   5) thickness t (m)
%   6) Ls (m)
%   7) Lt (m)
%   8) Lr (m)
%   9) h (m)
%   10) nose mass (kg)
%   11) fin flutter FOS
results = NaN(num_elements, 11);

% If you have a custom flutter function, define or replace here:
f_flutter = @FOS_finflutter; 

row_index = 1;

%% 5. BRUTE-FORCE LOOP
tic;  % Start timer to estimate remaining time

for i = 1:num_elements

    % Estimate time remaining:
    if i > 1
        elapsedTime = toc;                  % total time so far [s]
        avgTimePerIter = elapsedTime / (i-1);
        remainingIters = num_elements - i + 1;
        estRemSec = avgTimePerIter * remainingIters;
        estRemStr = datestr(seconds(estRemSec), 'HH:MM:SS');
    else
        estRemStr = "N/A";  % For iteration #1, we can't estimate yet
    end
    
    % Extract geometry & nose mass from the grid
    on_t     = t_g(i);
    on_Ls    = Ls_g(i);
    on_Lt    = Lt_g(i);
    on_Lr    = Lr_g(i);
    on_h     = h_g(i);
    on_noseM = nose_g(i);
    
    % Update fin geometry
    fins.setThickness(on_t); 
    fins.setSweepAngle(on_Ls);
    fins.setTipChord(on_Lt);
    fins.setRootChord(on_Lr);
    fins.setHeight(on_h);
    
    % Update nose weight
    NoseWeight.setComponentMass(on_noseM);
    
    % Rerun the simulation with updated geometry & nose mass
    sim = otis.sims(sim_name);
    opts = sim.getOptions;
    opts.setWindSpeedDeviation(wind_speed_deviation);
    opts.setTimeStep(time_step);
    
    openrocket.simulate(sim);
    data = openrocket.get_data(sim);

    % -------- EXTRACT PERFORMANCE METRICS --------
    
    % Apogee [m]
    apogee_m = data{eventfilter("APOGEE"), "Altitude"};
    
    % Fin Flutter FOS
    FINAL_FOS = f_flutter(data, fins);
    sweepAngle = atan(on_Ls/on_h);
    sweepAngle = rad2deg(sweepAngle);
    
    % Entire flight stability margin
    stability_all = data{:,"Stability margin"};
    maxStability  = max(stability_all);
    
    % Stability off the launch rail (first sample after LAUNCHROD)
    data_range = timerange(eventfilter("LAUNCHROD"), eventfilter("BURNOUT"), "openleft");
    data_trim = data(data_range, :);
    if isempty(data_trim)
        % fallback if no data in that range
        stb_launchrod = stability_all(1);
    else
        stb_launchrod = data_trim{1,"Stability margin"};
    end

    % -------- ENFORCE CONSTRAINTS --------
    pass_constraints = (FINAL_FOS > FOS_min) && ...
                       (stb_launchrod > stability_rail) && ...
                       (maxStability < stability_max) && ...
                       (apogee_m > apogee_lower) && (apogee_m < apogee_upper)&&...
                       (sweepAngle>minSweepAngle);

    % Console feedback: PASS or FAIL + parameter listing + est. time remaining
    if pass_constraints
        fprintf("Iteration %d of %d => t=%.5f, Ls=%.5f, Lt=%.5f, Lr=%.5f, h=%.5f,FoS =%.4f,stabRodMax=%.3f %.3f,sweepAngle=%.3f, noseMass=%.3f => PASS | Time Rem: %s\n", ...
            i, num_elements, on_t, on_Ls, on_Lt, on_Lr, on_h, FINAL_FOS, stb_launchrod,maxStability,sweepAngle, on_noseM, estRemStr);
        % Keep if it meets all constraints
        results(row_index,:) = [ i, apogee_m, maxStability, stb_launchrod, ...
                                 on_t, on_Ls, on_Lt, on_Lr, on_h, on_noseM, FINAL_FOS];
        row_index = row_index + 1;
    else
        fprintf("Iteration %d of %d => t=%.5f, Ls=%.5f, Lt=%.5f, Lr=%.5f, h=%.5f,FoS =%.4f,stabRodMax=%.3f %.3f,sweepAngle=%.3f, noseMass=%.3f => FAIL | Time Rem: %s\n", ...
            i, num_elements, on_t, on_Ls, on_Lt, on_Lr, on_h,FINAL_FOS, stb_launchrod,maxStability,sweepAngle,on_noseM, estRemStr);
    end
    
end

%% 6. TRIM RESULTS & FIND THE "BEST" DESIGN (MIN NOSE MASS)

% Remove unfilled rows
results = results(~any(isnan(results),2), :);

if isempty(results)
    disp("No designs satisfied the constraints!");
    return
end

% Among valid designs, pick the one with minimal nose mass
[~, idx_minNose] = min(results(:,10));  % col 10 is noseMass
best_design = results(idx_minNose, :);

%% 7. DISPLAY RESULTS

titles = {
    'Iter#','Apogee(m)','MaxStab','Stab@Rail','t(m)','Ls(m)', ...
    'Lt(m)','Lr(m)','h(m)','NoseMass(kg)','FOS'
};

fprintf('\nAll Valid Solutions:\n');
fprintf('%-6s %-10s %-10s %-10s %-8s %-8s %-8s %-8s %-8s %-12s %-8s\n', titles{:});
for r = 1:size(results,1)
    fprintf('%-6d %-10.1f %-10.3f %-10.3f %-8.5f %-8.5f %-8.5f %-8.5f %-8.5f %-12.5f %-8.3f\n',...
        results(r,1), results(r,2), results(r,3), results(r,4), ...
        results(r,5), results(r,6), results(r,7), results(r,8), ...
        results(r,9), results(r,10), results(r,11));
end

disp(" ");
disp("BEST DESIGN (minimal Nose Mass among constraints):");
disp(array2table(best_design, 'VariableNames', titles));

%% 8. QUICK DATA VISUALIZATION & HIGHLIGHT BEST DESIGN

figure('Name','Fin + Nose Weight Trade Study - MKS','Color','w');
set(gcf,'Position',[100 100 1200 600]);

% Unpack "best design" for quick reference
best_noseM   = best_design(10);
best_apogee  = best_design(2);
best_stabRail= best_design(4);
best_maxStab = best_design(3);
best_FOS     = best_design(11);

% (a) Apogee vs NoseMass
subplot(2,2,1);
scatter(results(:,10), results(:,2), 30, 'b','filled'); hold on;
scatter(best_noseM, best_apogee, 120, 'rp', 'filled'); % highlight best
xlabel('Nose Mass [kg]'); ylabel('Apogee [m]');
title('Apogee vs Nose Mass'); grid on;

% (b) Stability off Rail vs NoseMass
subplot(2,2,2);
scatter(results(:,10), results(:,4), 30, 'r','filled'); hold on;
scatter(best_noseM, best_stabRail, 120, 'kp', 'filled'); % highlight best
xlabel('Nose Mass [kg]'); ylabel('Stability @ Rail');
title('Stability @ Rail vs Nose Mass'); grid on;

% (c) Max Stability vs Apogee
subplot(2,2,3);
scatter(results(:,2), results(:,3), 30, 'g','filled'); hold on;
scatter(best_apogee, best_maxStab, 120, 'mp', 'filled'); % highlight best
xlabel('Apogee [m]'); ylabel('Max Stability');
title('Max Stability vs Apogee'); grid on;

% (d) FOS vs NoseMass
subplot(2,2,4);
scatter(results(:,10), results(:,11), 30, 'k','filled'); hold on;
scatter(best_noseM, best_FOS, 120, 'gp', 'filled'); % highlight best
xlabel('Nose Mass [kg]'); ylabel('Fin Flutter FOS');
title('FOS vs Nose Mass'); grid on;

%% 9. RE-RUN THE BEST DESIGN AND PLOT STABILITY VS TIME

% Pull out geometry from best design
best_t     = best_design(5);
best_Ls    = best_design(6);
best_Lt    = best_design(7);
best_Lr    = best_design(8);
best_h     = best_design(9);
best_noseM = best_design(10);

% Update the rocket to the best design
fins.setThickness(best_t);
fins.setSweep(best_Ls);
fins.setTipChord(best_Lt);
fins.setRootChord(best_Lr);
fins.setHeight(best_h);
NoseWeight.setComponentMass(best_noseM);

% Re-run sim to get time-history data
sim_best = otis.sims(sim_name);
opts_best = sim_best.getOptions;
opts_best.setWindSpeedDeviation(wind_speed_deviation);
opts_best.setTimeStep(time_step);

openrocket.simulate(sim_best);
data_best = openrocket.get_data(sim_best);

% Plot Stability vs Time
figure('Name','Stability vs Time - Best Design','Color','w');
plot(data_best.Time, data_best{:,"Stability margin"}, 'LineWidth',2);
grid on;
xlabel('Time [s]');
ylabel('Stability Margin [cal]');
title('Best Design: Stability vs. Time');

%% (After your current plots, add the following sections)

% Create a table for easier plotting and labeling
resultsTable = array2table(results, 'VariableNames', titles);
% Note: titles = {'Iter#','Apogee(m)','MaxStab','Stab@Rail',...
%                    't(m)','Ls(m)','Lt(m)','Lr(m)','h(m)',...
%                    'NoseMass(kg)','FOS'};

%% A. Scatter-Matrix Plot for Design Parameters & Performance Metrics
% This plot shows pairwise relationships between key design variables and performance metrics.
figure('Name','Scatter Matrix: Design vs. Performance','Color','w');
varsToPlot = {'t(m)', 'Ls(m)', 'Lt(m)', 'Lr(m)', 'h(m)', 'NoseMass(kg)', 'Apogee(m)', 'MaxStab', 'Stab@Rail', 'FOS'};
plotmatrix(resultsTable{:,varsToPlot});
sgtitle('Scatter Matrix of Design Variables & Performance Metrics');

%% B. 3D Scatter Plot Highlighting the Best Design
% For example, plot Nose Mass vs. Apogee vs. Max Stability.
figure('Name','3D Scatter: NoseMass vs Apogee vs MaxStability','Color','w');
scatter3(results(:,10), results(:,2), results(:,3), 50, results(:,11), 'filled'); hold on;
scatter3(best_design(10), best_design(2), best_design(3), 120, 'rp', 'filled');  % best design marker
xlabel('NoseMass (kg)');
ylabel('Apogee (m)');
zlabel('Max Stability');
cb = colorbar;
cb.Label.String = 'Fin Flutter FOS';
title('3D Scatter Plot: Performance Metrics with Best Design Highlighted');
grid on;

%% C. Parallel Coordinates Plot to Visualize Multi-dimensional Data
% This plot allows you to see how each candidate (each row) behaves across all metrics.
% To emphasize the best design, we create a grouping variable.
isBest = resultsTable.("Iter#") == best_design(1);  % true for best design, false otherwise
group = repmat("Other", height(resultsTable), 1);
group(isBest) = "Best";
% Use the parallelcoords function (requires Statistics Toolbox)
figure('Name','Parallel Coordinates Plot','Color','w');
% Choose the columns of interest: design variables and key performance metrics.
colsForParallel = {'t(m)', 'Ls(m)', 'Lt(m)', 'Lr(m)', 'h(m)', 'NoseMass(kg)', 'Apogee(m)', 'MaxStab', 'Stab@Rail', 'FOS'};
parallelcoords(resultsTable{:,colsForParallel}, 'Group', group, ...
    'Standardize', 'on', 'Labels', colsForParallel);
title('Parallel Coordinates Plot (Best Design Highlighted)');
legend('Other Designs','Best Design');

%% D. Interactive Visualization (Optional)
% If you have MATLAB R2018b or later, you can use the scatter3 with data tips or the brush tool.
% For example, you might create an interactive 3D scatter plot:
figure('Name','Interactive 3D Scatter','Color','w');
hScatter = scatter3(results(:,10), results(:,2), results(:,3), 50, results(:,11), 'filled');
xlabel('NoseMass (kg)');
ylabel('Apogee (m)');
zlabel('Max Stability');
title('Interactive 3D Scatter Plot');
colorbar;
grid on;
% Enable data cursor mode to click on points and see their design parameters.
datacursormode on;


%% NEW VISUALIZATION: Parameter Sweeps (Nose Mass vs Fin Sweep) and Performance Metrics

% Extract candidate design data from results matrix:
% Column indices:
%   2 -> Apogee (m)
%   3 -> Max Stability
%   4 -> Stability @ Rail
%   6 -> Fin Sweep (Ls, in m)
%   10 -> Nose Mass (kg)
%   11 -> Fin Flutter FOS

noseMass_data = results(:,10);
Ls_data       = results(:,6);

% Define a grid for interpolation
numGridPts = 50; % Adjust as needed for smoothness
xi = linspace(min(noseMass_data), max(noseMass_data), numGridPts);
yi = linspace(min(Ls_data), max(Ls_data), numGridPts);
[XI, YI] = meshgrid(xi, yi);

% Interpolate performance metrics onto the grid:
ZI_apogee   = griddata(noseMass_data, Ls_data, results(:,2), XI, YI, 'linear');
ZI_FOS      = griddata(noseMass_data, Ls_data, results(:,11), XI, YI, 'linear');
ZI_stabRail = griddata(noseMass_data, Ls_data, results(:,4), XI, YI, 'linear');
ZI_maxStab  = griddata(noseMass_data, Ls_data, results(:,3), XI, YI, 'linear');

figure('Name','Parameter Sweeps: Performance vs. Nose Mass & Fin Sweep','Color','w');
set(gcf,'Position',[100 100 1200 800]);

% (a) Apogee vs. Nose Mass & Fin Sweep
subplot(2,2,1);
contourf(XI, YI, ZI_apogee, 20, 'LineColor', 'none');
colorbar;
hold on;
plot(best_design(10), best_design(6), 'r*', 'MarkerSize', 12, 'LineWidth', 2);
xlabel('Nose Mass (kg)');
ylabel('Fin Sweep (m)');
title('Apogee (m)');
grid on;

% (b) Fin Flutter FOS vs. Nose Mass & Fin Sweep
subplot(2,2,2);
contourf(XI, YI, ZI_FOS, 20, 'LineColor', 'none');
colorbar;
hold on;
plot(best_design(10), best_design(6), 'r*', 'MarkerSize', 12, 'LineWidth', 2);
xlabel('Nose Mass (kg)');
ylabel('Fin Sweep (m)');
title('Fin Flutter FOS');
grid on;

% (c) Stability @ Rail vs. Nose Mass & Fin Sweep
subplot(2,2,3);
contourf(XI, YI, ZI_stabRail, 20, 'LineColor', 'none');
colorbar;
hold on;
plot(best_design(10), best_design(6), 'r*', 'MarkerSize', 12, 'LineWidth', 2);
xlabel('Nose Mass (kg)');
ylabel('Fin Sweep (m)');
title('Stability @ Rail');
grid on;

% (d) Maximum Stability vs. Nose Mass & Fin Sweep
subplot(2,2,4);
contourf(XI, YI, ZI_maxStab, 20, 'LineColor', 'none');
colorbar;
hold on;
plot(best_design(10), best_design(6), 'r*', 'MarkerSize', 12, 'LineWidth', 2);
xlabel('Nose Mass (kg)');
ylabel('Fin Sweep (m)');
title('Max Stability');
grid on;

sgtitle('Performance Metrics as a Function of Nose Mass and Fin Sweep');

%% NEW VISUALIZATION: 3D Multi-dimensional Plot Combining Design & Performance Metrics

% Extract key variables from the results matrix
% Columns in results are:
% 2) Apogee (m)
% 3) Max Stability
% 4) Stability @ Rail
% 6) Fin Sweep (Ls, m)
% 10) Nose Mass (kg)
% 11) Fin Flutter FOS

noseMass = results(:,10);  % Nose Mass (kg)
finSweep = results(:,6);   % Fin Sweep (m)
apogee   = results(:,2);   % Apogee (m)
FOS      = results(:,11);  % Fin Flutter FOS
maxStab  = results(:,3);   % Maximum Stability

% Scale the marker sizes based on max stability (for example, between 10 and 100)
msizes = 10 + 90 * (maxStab - min(maxStab)) / (max(maxStab) - min(maxStab));

% Create the 3D scatter plot
figure('Name','3D Multi-dimensional Plot','Color','w');
scatter3(noseMass, finSweep, apogee, msizes, FOS, 'filled');
xlabel('Nose Mass (kg)', 'FontSize',12);
ylabel('Fin Sweep (m)', 'FontSize',12);
zlabel('Apogee (m)', 'FontSize',12);
title('3D Multi-dimensional Plot: Design & Performance Metrics', 'FontSize',14);
colorbar;
colormap(jet);
grid on;
hold on;

% Highlight the best design with a distinctive marker (e.g., a large pentagram)
scatter3(best_design(10), best_design(6), best_design(2), 150, best_design(11), 'p', 'filled', 'MarkerEdgeColor', 'k');

legend('Candidate Designs','Best Design','Location','best');


%% Multi-Plot: Stability vs Time for Different Winner Designs

% Determine winners among valid designs:
% Winner 1: Best design by minimal nose mass (already computed)
winner_lowNose = best_design;

% Winner 2: Design with highest Fin Flutter FOS (column 11)
[~, idx_maxFOS] = max(results(:,11));
winner_maxFOS = results(idx_maxFOS,:);

% Winner 3: Design with highest Apogee (column 2)
[~, idx_maxApo] = max(results(:,2));
winner_maxApo = results(idx_maxApo,:);

% Create cell arrays for convenience
winners = {winner_lowNose, winner_maxFOS, winner_maxApo};
winnerNames = {'Lowest Nose Mass','Highest Fin Flutter FOS','Highest Apogee'};

% Create a new figure for the multi-plot
figure('Name','Stability vs Time for Different Winner Designs','Color','w');
hold on;
colors = lines(numel(winners));  % Use a colormap with distinct colors

for j = 1:length(winners)
    design = winners{j};
    
    % Update rocket design parameters for the j-th candidate:
    % Columns: 5=t, 6=Ls, 7=Lt, 8=Lr, 9=h, 10=nose mass
    fins.setThickness(design(5));
    fins.setSweepAngle(design(6));
    fins.setTipChord(design(7));
    fins.setRootChord(design(8));
    fins.setHeight(design(9));
    NoseWeight.setComponentMass(design(10));
    
    % Re-run the simulation for this design:
    sim_winner = otis.sims(sim_name);
    opts_winner = sim_winner.getOptions;
    opts_winner.setWindSpeedDeviation(wind_speed_deviation);
    opts_winner.setTimeStep(time_step);
    openrocket.simulate(sim_winner);
    data_winner = openrocket.get_data(sim_winner);
    
    % Extract time and Stability margin from the simulation data:
    time_vec = data_winner.Time;
    stab_margin = data_winner{:,"Stability margin"};
    
    % Extract the apogee (assumes your eventfilter("APOGEE") works as in the main loop)
    apogee_val = data_winner{eventfilter("APOGEE"), "Altitude"};
    
    % Create a custom legend text that includes the apogee value:
    legendText = sprintf('%s (Apogee: %.1f m)', winnerNames{j}, apogee_val);
    
    % Plot the Stability margin vs Time with the custom legend entry:
    plot(time_vec, stab_margin, 'LineWidth', 2, ...
         'Color', colors(j,:), 'DisplayName', legendText);
end

xlabel('Time [s]');
ylabel('Stability Margin');
title('Stability vs Time for Different Winner Designs');
legend('Location','best');
grid on;
hold off;
