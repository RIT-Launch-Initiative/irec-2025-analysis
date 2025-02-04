%% FIN + NOSE WEIGHT OPTIMIZATION IN MKS
%  Updated on 2/2/25
%  This script runs a trade study on fin geometry and nose weight to meet
%  certain constraints on stability, FOS, and apogee.
%  All user-adjustable variables are centralized in the '%% USER INPUTS' section.

clear; close all;

%% USER INPUTS

% 1) Path to your metric .ork file
rocket_file_path = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";

% 2) Simulation ID to run (must exist in the .ork file)
sim_id = "15MPH-TEXAS-36C-(TYP)";

% 3) Fin thickness range [m]
%    (Currently set to a single value, but can be an array)
t_vals = [0.0047625]; % e.g. ~3/16 in

% 4) Scale factors for Fin geometry (sweep, tip chord, root chord, height)
%    Each uses a multiplier around 1.0 to scale the nominal dimension from OpenRocket.
%    Below is an example with only height being varied.
Ls_scale = [1.0];
Lt_scale = [1.0];
Lr_scale = [1.0];
h_scale  = 0.8 : 0.05 : 1.2; % vary from 80% to 120% of nominal height

% 5) Nose cone adjustable weight [kg]
%    Range from 0 to 0.5 kg in steps of 0.05.
nose_mass_vals = 0.00 : 0.05 : 0.50;

% 6) Constraints:
FOS_min = 1.5;          % Minimum fin flutter factor-of-safety
stability_rail_min = 1.0;  % Minimum stability margin off the launch rail
stability_max = 4.0;    % Maximum acceptable stability margin in flight
apogee_min = 2895.6;    % 10k ft minus 5% -> ~2896 m
apogee_max = 3200.4;    % 10k ft plus 5%  -> ~3200 m

% 7) Fin flutter function handle (if you have a custom function, set it here)
f_flutter = @FOS_finflutter;

%% 1. LOAD ROCKET + KEY COMPONENTS

if ~isfile(rocket_file_path)
    error("Error: cannot find .ork file: %s", rocket_file_path);
end

% Load rocket
otis = openrocket(rocket_file_path);

% Select the simulation by name
sim = otis.sims(sim_id);
opts = sim.getOptions;
opts.setWindSpeedDeviation(0);
opts.setTimeStep(0.05);

% Access the single FinSet component
fins = otis.component(class="FinSet");
if ~isscalar(fins)
    error("Error: multiple fin sets found");
end

% Access the adjustable nose weight component by name
NoseWeight = otis.component(name="Adjustable stability weight");
if isempty(NoseWeight)
    error("Error: No nose weight component found by that name!");
end

%% 2. RETRIEVE NOMINAL FIN DIMENSIONS FROM OPENROCKET

Ls_or = fins.getSweep();       % nominal sweep [m]
Lt_or = fins.getTipChord();    % nominal tip chord [m]
Lr_or = fins.getRootChord();   % nominal root chord [m]
h_or  = fins.getHeight();      % nominal fin height [m]

% Create full factor sets
[t_g, Ls_g, Lt_g, Lr_g, h_g, nose_g] = ndgrid(...
    t_vals, Ls_scale, Lt_scale, Lr_scale, h_scale, nose_mass_vals);

num_elements = numel(t_g);
fprintf("Total # of candidate designs: %d\n", num_elements);

%% 3. PRE-ALLOCATE RESULTS

% We'll collect:
% [ iteration#, Apogee(m), maxStability, stabLaunchrod, t(m), Ls(m), Lt(m), Lr(m), h(m), NoseMass(kg), FOS ]
results = NaN(num_elements, 11);
row_index = 1;

%% 4. BRUTE FORCE LOOP

for i = 1:num_elements

    %% EXTRACT geometry & nose mass from the ND-grid
    on_t     = t_g(i);
    on_Ls    = Ls_or * Ls_g(i);
    on_Lt    = Lt_or * Lt_g(i);
    on_Lr    = Lr_or * Lr_g(i);
    on_h     = h_or  * h_g(i);
    on_noseM = nose_g(i);

    %% Update the fin geometry
    fins.setThickness(on_t);
    fins.setSweepAngle(on_Ls);
    fins.setTipChord(on_Lt);
    fins.setRootChord(on_Lr);
    fins.setHeight(on_h);

    %% Update the nose weight (in kg)
    NoseWeight.setMassOverridden(on_noseM);

    %% Re-run simulation with updated geometry + nose mass
    sim = otis.sims(sim_id);
    opts = sim.getOptions;
    opts.setWindSpeedDeviation(0);
    openrocket.simulate(sim);
    data = openrocket.get_data(sim);

    %% EXTRACT PERFORMANCE METRICS
    % If multiple APOGEE events exist, take the max altitude.
    apogee_vals = data{eventfilter("APOGEE"), "Altitude"};
    if isempty(apogee_vals)
        % If no apogee event found, skip.
        continue;
    end
    apogee_m = max(apogee_vals);

    % Fin Flutter FOS
    FINAL_FOS = f_flutter(data, fins);  % must be > FOS_min

    % Entire flight stability margin
    stability_all = data{:,"Stability margin"};
    maxStability  = max(stability_all);

    % Stability off the rail
    data_range = timerange(eventfilter("LAUNCHROD"), eventfilter("BURNOUT"), "openleft");
    data_trim = data(data_range, :);
    if isempty(data_trim)
        stb_launchrod = stability_all(1);
    else
        stabilityMargin_trim = data_trim{:,"Stability margin"};
        stb_launchrod = stabilityMargin_trim(1);
    end

    %% ENFORCE CONSTRAINTS
    if (FINAL_FOS > FOS_min) && ...
       (stb_launchrod > stability_rail_min) && ...
       (maxStability < stability_max) && ...
       (apogee_m > apogee_min) && (apogee_m < apogee_max)

        results(row_index,:) = [i, apogee_m, maxStability, stb_launchrod,
                                on_t, on_Ls, on_Lt, on_Lr, on_h, on_noseM, FINAL_FOS];
        row_index = row_index + 1;
    end
end

%% 5. TRIM RESULTS & FIND "BEST" DESIGN

results = results(~any(isnan(results),2), :);
% columns:
%   1) iteration index
%   2) apogee(m)
%   3) maxStability
%   4) stability@rail
%   5) t (m)
%   6) Ls (m)
%   7) Lt (m)
%   8) Lr (m)
%   9) h (m)
%   10) noseMass(kg)
%   11) FOS

if isempty(results)
    disp("No designs satisfied the constraints!");
    return;
end

[~, idx_minNose] = min(results(:,10));  % col 10 is noseMass
best_design = results(idx_minNose, :);

%% 6. DISPLAY RESULTS

titles = { 'Iter#','Apogee(m)','MaxStab','Stab@Rail','t(m)','Ls(m)',...
            'Lt(m)','Lr(m)','h(m)','NoseMass(kg)','FOS'};

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

%% 7. VISUALIZATION OF ALL VALID DESIGNS

figure('Name','Overview of Fin + Nose Weight Trade Study','Color','w');

subplot(2,2,1);
scatter(results(:,10), results(:,2), 30, 'b','filled');
hold on;
plot(best_design(10), best_design(2), 'rp', 'MarkerSize',10, 'MarkerFaceColor','r');
xlabel('Nose Mass [kg]');
ylabel('Apogee [m]');
title('Apogee vs Nose Mass');
grid on;

subplot(2,2,2);
scatter(results(:,10), results(:,4), 30, 'r','filled');
hold on;
plot(best_design(10), best_design(4), 'bp', 'MarkerSize',10, 'MarkerFaceColor','b');
xlabel('Nose Mass [kg]');
ylabel('Stability @ Rail');
title('Stability @ Rail vs Nose Mass');
grid on;

subplot(2,2,3);
scatter(results(:,2), results(:,3), 30, 'g','filled');
hold on;
plot(best_design(2), best_design(3), 'ks', 'MarkerSize',8, 'MarkerFaceColor','k');
xlabel('Apogee [m]');
ylabel('Max Stability');
title('Max Stability vs Apogee');
grid on;

subplot(2,2,4);
scatter(results(:,10), results(:,11), 30, 'k','filled');
hold on;
plot(best_design(10), best_design(11), 'gs', 'MarkerSize',8, 'MarkerFaceColor','g');
xlabel('Nose Mass [kg]');
ylabel('Fin Flutter FOS');
title('FOS vs Nose Mass');
grid on;

%% 8. RUN SIM FOR BEST DESIGN & PLOT STABILITY VS TIME

% Re-assign geometry to match best design
best_t         = best_design(5);
best_Ls        = best_design(6);
best_Lt        = best_design(7);
best_Lr        = best_design(8);
best_h         = best_design(9);
best_nose_mass = best_design(10);

fins.setThickness(best_t);
fins.setSweepAngle(best_Ls);
fins.setTipChord(best_Lt);
fins.setRootChord(best_Lr);
fins.setHeight(best_h);

NoseWeight.setMassOverridden(best_nose_mass);

best_sim = otis.sims(sim_id);
opts_best = best_sim.getOptions;
opts_best.setWindSpeedDeviation(0);
openrocket.simulate(best_sim);
best_data = openrocket.get_data(best_sim);

% Plot stability vs time
figure('Name','Best Design Stability vs Time','Color','w');

subplot(2,1,1);
plot(best_data{:,'Time'}, best_data{:,'Stability margin'}, 'LineWidth',1.5);
xlabel('Time [s]');
ylabel('Stability Margin');
title('Best Design: Stability vs Time');
grid on;

subplot(2,1,2);
plot(best_data{:,'Time'}, best_data{:,'Altitude'}, 'LineWidth',1.5);
xlabel('Time [s]');
ylabel('Altitude [m]');
title('Best Design: Altitude vs Time');
grid on;