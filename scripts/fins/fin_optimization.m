%% FIN + NOSE WEIGHT OPTIMIZATION
%  Created by Ares Bustinza-Nguyen
%  Updated: 2/6/25,
%
%  This script brute-forces a range of fin geometries & nose weights,
%  re-simulates in OpenRocket, and checks constraints.
%  The "best" design is the one that meets constraints and is closest to a 
%  specified target apogee (by default 3086 m ~ 10125 ft).

clear; close all;

%% 0. DEFINE CONVERSION FACTORS
m2ft = 3.28084;   % 1 meter = 3.28084 feet
m2in = 39.3701;   % 1 meter = 39.3701 inches

%% 1. USER INPUTS (EDIT THESE ONLY)

% Path to your metric .ork file
ork_file_path = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
addpath(genpath("C:\lmatlib\sim"));

% Name of the OpenRocket simulation to run
sim_name = "15MPH-TEXAS-36C-(TYP)";

% Wind speed deviation (set to 0 if you want a deterministic run)
wind_speed_deviation = 0;

% Desired time step for simulation [s]
time_step = 0.01;

% Fin thickness values [m]
% Example: 0.003175 m ~ 1/8 in, 0.0047625 m ~ 3/16 in, 0.00635 m ~ 1/4 in
t_vals = [0.00635];

% Sweep, tip chord, root chord, and height scaling:
% For demonstration, these are left at 1 (no scaling).
Ls_scale = 1;
h_scale  = 1;
Lt_scale = 1;
Lr_scale = 1;

% Range of nose cone adjustable weight [kg]
nose_mass_vals = 0:0.1:1;

% Constraints (values remain in metric for simulation purposes)
FOS_min         = 1.5;    % Fin flutter factor of safety must be > 1.5
stability_rail  = 1.5;    % Stability margin off rail must be > 1.4 (example)
stability_max   = 3.95;   % Max stability during flight must be < 4.0
apogee_lower    = 2980;   % Example lower bound near target_apogee
target_apogee   = 3086;   % Target apogee you want to get close to [m]
apogee_upper    = 3280;   % Example upper bound near target_apogee
minSweepAngle   = 20;     % Minimum sweep angle in degrees

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

% Create numeric arrays for each parameter using the scale factors:
Ls_vals = Ls_nom * Ls_scale;
Lt_vals = Lt_nom * Lt_scale;
Lr_vals = Lr_nom * Lr_scale;
h_vals  = h_nom  * h_scale;

[t_g, Ls_g, Lt_g, Lr_g, h_g, nose_g] = ndgrid( ...
    t_vals, Ls_vals, Lt_vals, Lr_vals, h_vals, nose_mass_vals);

num_elements = numel(t_g);
fprintf("Total # of candidate designs: %d\n", num_elements);

%% 4. PRE-ALLOCATE RESULTS
% Now we add a 12th column for burnout stability.
%
% Columns of 'results':
%   1) iteration index
%   2) apogee (m)
%   3) max stability (over flight)
%   4) stability off the rail (first sample after LAUNCHROD)
%   5) thickness t (m)
%   6) Ls (m)
%   7) Lt (m)
%   8) Lr (m)
%   9) h (m)
%   10) nose mass (kg)
%   11) fin flutter FOS
%   12) stability at burnout (from BURNOUT event)
results = NaN(num_elements, 12);

% If you have a custom flutter function, define/replace here:
f_flutter = @FOS_finflutter;

row_index = 1;

%% 5. BRUTE-FORCE LOOP
tic;  % Start timer to estimate remaining time

for i = 1:num_elements

    % Estimate time remaining:
    if i > 1
        elapsedTime = toc;
        avgTimePerIter = elapsedTime / (i-1);
        remainingIters = num_elements - i + 1;
        estRemSec = avgTimePerIter * remainingIters;
        estRemStr = datestr(seconds(estRemSec), 'HH:MM:SS');
    else
        estRemStr = "N/A";
    end

    % Extract geometry & nose mass from the grid (in metric)
    on_t     = t_g(i);
    on_Ls    = Ls_g(i);
    on_Lt    = Lt_g(i);
    on_Lr    = Lr_g(i);
    on_h     = h_g(i);
    on_noseM = nose_g(i);

    % Convert key dimensions to inches for console output
    on_t_in  = on_t  * m2in;
    on_Ls_in = on_Ls * m2in;
    on_Lt_in = on_Lt * m2in;
    on_Lr_in = on_Lr * m2in;
    on_h_in  = on_h  * m2in;

    % Update fin geometry in the rocket
    fins.setThickness(on_t);
    fins.setSweep(on_Ls);
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

    % Apogee [m] → we will convert to ft for console reporting
    apogee_m = data{eventfilter("APOGEE"), "Altitude"};
    apogee_ft = apogee_m * m2ft;

    % Fin Flutter FOS
    FINAL_FOS = f_flutter(data, fins);

    % Sweep angle in degrees (for constraint checking)
    sweepAngle = rad2deg( atan(on_Ls / on_h) );

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

    % ----- NEW: Extract Stability at Burnout -----
    stability_burnout = data{eventfilter("BURNOUT"), "Stability margin"};
    if isempty(stability_burnout)
        stability_burnout = maxStability;  % fallback if no burnout data
    else
        stability_burnout = stability_burnout(1);
    end

    % -------- ENFORCE CONSTRAINTS --------
    pass_constraints = (FINAL_FOS > FOS_min) && ...
                       (stb_launchrod > stability_rail) && ...
                       (maxStability < stability_max) && ...
                       (apogee_m > apogee_lower) && (apogee_m < apogee_upper) && ...
                       (sweepAngle > minSweepAngle);

    % Console feedback: PASS or FAIL
    if pass_constraints
        fprintf("Iteration %d of %d => t=%.5f in, Ls=%.5f in, Lt=%.5f in, Lr=%.5f in, h=%.5f in, Apogee=%.1f ft, FoS=%.4f, stabRod=%.3f, maxStab=%.3f, sweepAngle=%.3f°, noseMass=%.3f kg => PASS | Time Rem: %s\n", ...
            i, num_elements, on_t_in, on_Ls_in, on_Lt_in, on_Lr_in, on_h_in, ...
            apogee_ft, FINAL_FOS, stb_launchrod, maxStability, sweepAngle, on_noseM, estRemStr);

        % Keep if it meets all constraints
        results(row_index,:) = [ i, apogee_m, maxStability, stb_launchrod, ...
                                 on_t, on_Ls, on_Lt, on_Lr, on_h, on_noseM, FINAL_FOS, stability_burnout];
        row_index = row_index + 1;
    else
        fprintf("Iteration %d of %d => t=%.5f in, Ls=%.5f in, Lt=%.5f in, Lr=%.5f in, h=%.5f in, Apogee=%.1f ft, FoS=%.4f, stabRod=%.3f, maxStab=%.3f, sweepAngle=%.3f°, noseMass=%.3f kg => FAIL | Time Rem: %s\n", ...
            i, num_elements, on_t_in, on_Ls_in, on_Lt_in, on_Lr_in, on_h_in, ...
            apogee_ft, FINAL_FOS, stb_launchrod, maxStability, sweepAngle, on_noseM, estRemStr);
    end

end

%% 6. TRIM RESULTS & FIND THE "BEST" DESIGN (APOGEE CLOSEST TO target_apogee)

% Remove unfilled rows
results = results(~any(isnan(results),2), :);

if isempty(results)
    disp("No designs satisfied the constraints!");
    return
end

% Find the design whose apogee is closest to our target_apogee
[~, idx_closestApogee] = min(abs(results(:,2) - target_apogee));
best_design = results(idx_closestApogee, :);

%% DISPLAY THE WINNER IN THE CONSOLE

% For table display, we want:
%  - Apogee in ft
%  - Geometries in inches
%  - Nose mass in kg
%  - FOS dimensionless
conv_factors = [1, m2ft, 1, 1, m2in, m2in, m2in, m2in, m2in, 1, 1, 1];

% Updated column headers:
titles = {
    'Iter#','Apogee(ft)','MaxStab','Stab@Rail','t(in)','Ls(in)', ...
    'Lt(in)','Lr(in)','h(in)','NoseMass(kg)','FOS','Stab@Burnout'
};

disp(" ");
disp("BEST DESIGN (Apogee closest to target_apogee):");
disp(array2table(best_design .* conv_factors, 'VariableNames', titles));

%% 7. DISPLAY ALL VALID RESULTS

fprintf('\nAll Valid Solutions (geometry in inches, apogee in ft):\n');
fprintf('%-6s %-12s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-14s %-8s %-14s\n', titles{:});
for r = 1:size(results,1)
    fprintf('%-6d %-12.1f %-10.3f %-10.3f %-10.5f %-10.5f %-10.5f %-10.5f %-10.5f %-14.5f %-8.3f %-14.3f\n',...
        results(r,1), ...                     % Iter#
        results(r,2)*m2ft, ...               % Apogee(ft)
        results(r,3), ...                    % MaxStab
        results(r,4), ...                    % Stab@Rail
        results(r,5)*m2in, ...               % t(in)
        results(r,6)*m2in, ...               % Ls(in)
        results(r,7)*m2in, ...               % Lt(in)
        results(r,8)*m2in, ...               % Lr(in)
        results(r,9)*m2in, ...               % h(in)
        results(r,10), ...                   % NoseMass(kg)
        results(r,11), ...                   % FOS
        results(r,12));                      % Stab@Burnout
end

% Create a table for easier script-wide use
results_table = results;
results_table(:,2) = results_table(:,2) * m2ft;  % Apogee in ft
results_table(:,5) = results_table(:,5) * m2in;  % t in
results_table(:,6) = results_table(:,6) * m2in;  % Ls in
results_table(:,7) = results_table(:,7) * m2in;  % Lt in
results_table(:,8) = results_table(:,8) * m2in;  % Lr in
results_table(:,9) = results_table(:,9) * m2in;  % h in

%% 8. DATA VISUALIZATION & HIGHLIGHT BEST DESIGN

figure('Name','Fin + Nose Weight Trade Study (Inch Output in Console)','Color','w');
set(gcf,'Position',[100 100 1200 600]);

% Unpack "best design" for quick reference (convert appropriate metrics to ft for plotting)
best_noseM     = best_design(10);
best_apogee_ft = best_design(2) * m2ft;
best_stabRail  = best_design(4);
best_maxStab   = best_design(3);
best_FOS       = best_design(11);

% (a) Apogee vs NoseMass
subplot(2,2,1);
scatter(results(:,10), results(:,2)*m2ft, 30, 'b','filled'); hold on;
scatter(best_noseM, best_apogee_ft, 120, 'rp','filled');
xlabel('Nose Mass [kg]'); ylabel('Apogee [ft]');
title('Apogee vs Nose Mass'); grid on;

% (b) Stability off Rail vs NoseMass
subplot(2,2,2);
scatter(results(:,10), results(:,4), 30, 'r','filled'); hold on;
scatter(best_noseM, best_stabRail, 120, 'kp','filled');
xlabel('Nose Mass [kg]'); ylabel('Stability @ Rail');
title('Stability @ Rail vs Nose Mass'); grid on;

% (c) Max Stability vs Apogee
subplot(2,2,3);
scatter(results(:,2)*m2ft, results(:,3), 30, 'g','filled'); hold on;
scatter(best_apogee_ft, best_maxStab, 120, 'mp','filled');
xlabel('Apogee [ft]'); ylabel('Max Stability');
title('Max Stability vs Apogee'); grid on;

% (d) FOS vs NoseMass
subplot(2,2,4);
scatter(results(:,10), results(:,11), 30, 'k','filled'); hold on;
scatter(best_noseM, best_FOS, 120, 'gp','filled');
xlabel('Nose Mass [kg]'); ylabel('Fin Flutter FOS');
title('FOS vs Nose Mass'); grid on;

%% 8A. NEW: Plot Stability Margin vs. Each Design Variable
%
% For each swept variable, we plot two curves:
%  - Stability at Burnout (from the BURNOUT event)
%  - Stability at Launch Rod (first sample after LAUNCHROD)
%
% The swept variables are: fin thickness (t), fin sweep (Ls), fin tip chord (Lt),
% fin height (h) and nose mass.
figure('Name','Stability Margin vs Design Variables','Color','w','Position',[50 50 1200 600]);

% Prepare x-axis data (converted to inches for fin geometry, or left in kg for nose mass)
x_t   = results(:,5) * m2in;   % fin thickness in inches
x_Ls  = results(:,6) * m2in;   % fin sweep in inches
x_Lt  = results(:,7) * m2in;   % fin tip chord in inches
x_h   = results(:,9) * m2in;   % fin height in inches
x_nose = results(:,10);        % nose mass in kg
x_vars = {x_t, x_Ls, x_Lt, x_h, x_nose};
var_names = {'Fin Thickness t [in]', 'Fin Sweep Ls [in]', 'Fin Tip Chord Lt [in]', 'Fin Height h [in]', 'Nose Mass [kg]'};

% y-axis: stability margin at burnout and launch rod
y_burnout = results(:,12);
y_rail    = results(:,4);

for i = 1:length(x_vars)
    subplot(2,3,i);
    % To show trends, we sort the data by the x-variable
    [x_sorted, sortIdx] = sort(x_vars{i});
    y_burn_sorted = y_burnout(sortIdx);
    y_rail_sorted = y_rail(sortIdx);
    plot(x_sorted, y_burn_sorted, '-ob','LineWidth',1.5, 'MarkerFaceColor','b'); hold on;
    plot(x_sorted, y_rail_sorted, '-sr','LineWidth',1.5, 'MarkerFaceColor','r');
    xlabel(var_names{i});
    ylabel('Stability Margin');
    title(sprintf('Stability vs %s', var_names{i}));
    legend('Burnout','Launch Rod','Location','best');
    grid on;
end

%% 8B. NEW: Fin Area and Average Fin Position vs Stability @ Rail
%
% Fin Area is computed as:
%   A_fin = ((Lr + Lt)/2)*h
%
% The average fin position relative to the mid-root chord is computed as:
%   Let lambda = Lt/Lr,
%   x_cp = (Lr/3)*((1+2*lambda)/(1+lambda))
%   avg_fin_pos = x_cp - (Lr/2)
%
% (All dimensions are converted to inches for plotting.)
figure('Name','Fin Area and Average Fin Position vs Stability @ Rail','Color','w','Position',[150 150 1200 500]);

% Compute fin area [in^2]
fin_area_in = (((results(:,8)*m2in) + (results(:,7)*m2in)) / 2) .* (results(:,9)*m2in);

% Compute average fin position relative to the mid-root chord [in]
lambda = results(:,7) ./ results(:,8);  % Lt/Lr
x_cp = (results(:,8)/3) .* ((1 + 2*lambda) ./ (1 + lambda));  % in meters
avg_fin_pos_in = (x_cp - results(:,8)/2) * m2in;  % convert to inches

subplot(1,2,1);
scatter(fin_area_in, results(:,4), 40, 'filled');
xlabel('Fin Area [in^2]');
ylabel('Stability @ Rail');
title('Stability @ Rail vs Fin Area');
grid on;

subplot(1,2,2);
scatter(avg_fin_pos_in, results(:,4), 40, 'filled');
xlabel('Avg. Fin Position Rel. to Mid Root [in]');
ylabel('Stability @ Rail');
title('Stability @ Rail vs Avg. Fin Position');
grid on;

%% 9. RE-RUN THE BEST DESIGN AND PLOT STABILITY VS TIME
% Set rocket to best-design geometry & save

best_t     = best_design(5);
best_Ls    = best_design(6);
best_Lt    = best_design(7);
best_Lr    = best_design(8);
best_h     = best_design(9);
best_noseM = best_design(10);

fins.setThickness(best_t);
fins.setSweep(best_Ls);
fins.setTipChord(best_Lt);
fins.setRootChord(best_Lr);
fins.setHeight(best_h);
NoseWeight.setComponentMass(best_noseM);

% ** Save your final rocket configuration **
otis.save();

% Re-run simulation
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
ylabel('Stability Margin');
title('Best Design (Closest to Target Apogee): Stability vs. Time');

% Create a table for easier plotting and labeling
resultsTable = array2table(results_table, 'VariableNames', titles);
