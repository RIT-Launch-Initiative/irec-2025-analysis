clear; close all;

%% ── USER CONFIG ───────────────────────────────────────────────────────────
orkFilePath = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
simName     = "10MPH-TEXAS-36C-(TYP)";
addpath(genpath("C:\lmatlib"));
addpath(genpath("C:\lmatlib\sim"));

% Sweep ranges (edit as needed)
tempVals_C    = 20  : 1 : 30;    % °C2
windVals_mph  = 5  : 1 : 20;    % mph
noseMin_kg    = 1;              % lower mass bound
noseMax_kg    = 4;              % upper mass bound
targetApogee_ft = 10150;        % desired apogee

% Root-finder settings
tol_ft  = 50;      % stop when |apogee-target| < tol_ft
maxIter = 20;      % bisection iterations

%% ── CONSTANTS & PRE-ALLOCATIONS ──────────────────────────────────────────
ft2m   = 0.3048;      % ft → m
mph2ms = 0.44704;     % mph → m/s

nT = numel(tempVals_C);
nW = numel(windVals_mph);
numsims = nW*nT
massChart_kg = NaN(nT, nW);   % rows = temp, cols = wind

%% ── LOAD ROCKET + FIND NOSE WEIGHT COMPONENT ────────────────────────────
assert(isfile(orkFilePath), ".ork file not found: %s", orkFilePath);
otis = openrocket(orkFilePath);
NoseWeight = otis.component(name="Adjustable stability weight");
assert(~isempty(NoseWeight), "Component 'Adjustable stability weight' not found!");

%% ── MAIN GRID SEARCH ─────────────────────────────────────────────────────
for kT = 1:nT
    T_K = tempVals_C(kT) + 273.15;   % Kelvin
    disp(kT);
    for jW = 1:nW
        W_ms = windVals_mph(jW) * mph2ms;

        % Anonymous handle that gives apogee-error for a given mass
        f = @(m) apogeeDiff(m, T_K, W_ms, ...
                            ft2m, targetApogee_ft, ...
                            otis, NoseWeight, simName);

        % Evaluate at bracket bounds
        f_lo = f(noseMin_kg);
        f_hi = f(noseMax_kg);

        % If same sign → target unreachable within mass range
        if sign(f_lo) == sign(f_hi)
            massChart_kg(kT, jW) = NaN;
            continue;
        end

        % Bisection
        lo = noseMin_kg; hi = noseMax_kg; mid = (lo+hi)/2;
        for iter = 1:maxIter
            mid = 0.5*(lo+hi);
            f_mid = f(mid);
            if abs(f_mid) < tol_ft || (hi-lo) < 0.005   % stop when ≤10 g span
                break;     % converged
            end
            if sign(f_mid) == sign(f_lo)
                lo = mid; f_lo = f_mid;   % root in upper half
            else
                hi = mid; f_hi = f_mid;   % root in lower half
            end
        end
        % Store mass rounded to nearest 0.1 kg (100 g)
        massChart_kg(kT, jW) = mid;
    end
end

noseconemass()

%% --Weight sizing function--- %%
function weights = noseconemass(stab_weight)
    pucks= [1000 1000 500 500 500 100 100 100 100 50 50 25 25];

    
end


%% ── PLOT SIZING CHART ────────────────────────────────────────────────────
[T_mesh, W_mesh] = meshgrid(tempVals_C, windVals_mph);
T_mesh = T_mesh'; W_mesh = W_mesh';   % align with loops

[Tq,Wq]  = ndgrid(min(tempVals_C):0.25:max(tempVals_C), ...
                  min(windVals_mph):0.25:max(windVals_mph));
massFine = interp2(W_mesh, T_mesh, massChart_kg, Wq, Tq, 'linear');



fig = figure('Color','w');
levels = noseMin_kg : 0.1 : noseMax_kg;   % 0.1-kg contours
contourf(W_mesh, T_mesh, massChart_kg, levels, 'LineColor','none');
colormap(turbo);
hold on;
[C,h] = contour(W_mesh, T_mesh, massChart_kg, levels, '-k', 'LineWidth',0.7);
clabel(C, h, 'FontSize',7, 'Color','k', 'LabelSpacing',250);

figure('Color','w');
contourf(Wq, Tq, massFine, levels, 'LineColor','none');  % smoother contours

% Black-out impossible regions
mask = isnan(massChart_kg);
if any(mask,'all')
    contourf(W_mesh, T_mesh, double(mask), [0.5 0.5], 'LineColor','none', 'FaceColor','k');
end

grid on; box on;
xlabel('Wind speed [mph]');
ylabel('Ambient temperature [°C]');
cb = colorbar; cb.Label.String = 'Required nose mass [kg]';
title(sprintf('Mass required for %.0f ft AGL — 0.1 kg resolution', targetApogee_ft));

%% ── LOCAL FUNCTION -------------------------------------------------------
function diff = apogeeDiff(mass_kg, T_K, W_ms, ft2m, target_ft, otis, NoseWeight, simName)
    % Adjust component mass
    NoseWeight.setOverrideMass(mass_kg);
    NoseWeight.setComponentMass(mass_kg);

    % Fetch fresh sim handle each call (OpenRocket limitation)
    sim  = otis.sims(simName);
    opts = sim.getOptions();
    opts.setWindSpeedAverage(W_ms);
    opts.setWindSpeedDeviation(0);
    opts.setLaunchIntoWind(false);
    opts.setTimeStep(0.05);
    opts.setLaunchTemperature(T_K);

    % Run simulation
    data = openrocket.simulate(sim, outputs="Altitude");
    apogee_ft = max(data.Altitude) / ft2m;

    % Residual: positive if we overshoot target
    diff = apogee_ft - target_ft;
end

%% ── LOOK-UP TABLE --------------------------------------------------------
rowNames = compose('%d°C', tempVals_C);          % table rows
colNames = compose('%d_mph', windVals_mph);      % valid var names
Lookup = array2table(massChart_kg, ...
                     'RowNames', rowNames, ...
                     'VariableNames', matlab.lang.makeValidName(colNames));

disp('Required nose-mass [kg]  (rows = °C, cols = mph)');
disp(Lookup);

writetable(Lookup, 'nose_mass_lookup.csv', 'WriteRowNames', true);