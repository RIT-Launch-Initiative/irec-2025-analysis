clear; close all;

%% ── USER CONFIG ───────────────────────────────────────────────────────────
orkFilePath = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
simName     = "10MPH-TEXAS-36C-(TYP)";
addpath(genpath("C:\lmatlib"));
addpath(genpath("C:\lmatlib\sim"));

% Sweep ranges (edit resolution to taste)
noseMassVals = 2 : 0.2 : 6;      % kg  
windVals     = 0   : 1    : 9 ;       % m/s 

%% ── CONSTANTS & PRE‑ALLOCATIONS ───────────────────────────────────────────
m2ft   = 3.28084;       % metres  → feet
kg2lb  = 2.20462;       % kilograms → pounds‑mass
ms2fts = 3.28084;       % m/s → ft/s

nM = numel(noseMassVals);
nW = numel(windVals);
apogeeMat_m = NaN(nM, nW);   % rows: mass, cols: wind

%% ── LOAD ROCKET + FIND ADJUSTABLE NOSE WEIGHT ────────────────────────────
if ~isfile(orkFilePath)
    error(".ork file not found: %s", orkFilePath);
end
otis = openrocket(orkFilePath);
NoseWeight = otis.component(name="Adjustable stability weight");
if isempty(NoseWeight)
    error("Component 'Adjustable stability weight' not found!");
end
disp(nM)
%% ── SWEEP SIMULATIONS ─────────────────────────────────────────────────────
for iM = 1:nM
    NoseWeight.setOverrideMass( noseMassVals(iM) )
    NoseWeight.setComponentMass( noseMassVals(iM) )
    NoseWeight.setMassOverridden( noseMassVals(iM) )
    for jW = 1:nW
        sim  = otis.sims(simName);
        opts = sim.getOptions();
        opts.setLa
        opts.setWindSpeedAverage( windVals(jW) );
        opts.setWindSpeedDeviation( 0 );          % deterministic
        opts.setLaunchIntoWind(false);
        opts.setTimeStep(0.05);

        data = openrocket.simulate(sim, outputs="Altitude");
        apogeeMat_m(iM, jW) = max(data.Altitude);
        disp(iM)
    end
end

%% ── CONVERT UNITS FOR PLOTTING ───────────────────────────────────────────
Z_ft  = apogeeMat_m * m2ft;           % Z (contour) variable
X_fts = windVals;       % X vector (horizontal axis)
Y_lb  = noseMassVals;
[X,Y] = meshgrid(X_fts, Y_lb);        % expand so size(Z) == size(X)==size(Y)

%% ── CONTOUR LEVELS ────────────────────────────────────────────────────────
zMin = floor(min(Z_ft(:))/250)*250;
zMax = ceil( max(Z_ft(:))/250)*250;
levels = zMin : 250 : zMax;           % 250‑ft intervals

%% ── PLOTTING WITH *contour* (X, Y, Z) ─────────────────────────────────────
fig = figure('Color','w');
ax  = axes(fig);

% Use filled contours for background shading (optional aesthetic)
contourf(ax, X, Y, Z_ft, levels, 'LineColor','none');
colormap(ax, parula);
hold(ax, 'on');

% Overlay line contours (+ labels) using the same X,Y,Z syntax
[C,h] = contour(ax, X, Y, Z_ft, levels, '-k', 'LineWidth', 0.75);
clabel(C, h, 'FontSize', 8, 'Color', 'k', 'LabelSpacing', 300);

% Black‑out NaN regions (if any points were NaN)
mask = isnan(Z_ft);
if any(mask(:))
    contourf(ax, X, Y, double(mask), [0.5 0.5], 'LineColor','none', 'FaceColor','k');
end

% Axes styling
axis(ax, 'tight');
ax.Layer = 'top';          % grid lines on top of colour
ax.Box   = 'on';
ax.GridAlpha = 0.4;
set(ax, 'FontSize', 11);
grid(ax, 'on');

xlabel(ax, 'Wind Vel. [m/s]');
ylabel(ax, 'Mass [kg]');
title(ax, 'Apogee [ft AGL] | RIT-OTIS | MIDLAND TEXAS');

% Colour‑bar
cb = colorbar(ax);
cb.Label.String = 'Apogee [ft]';
cb.Ticks = levels(1:2:end);   % every other tick to declutter

%% ── OPTIONAL SAVES ────────────────────────────────────────────────────────
% exportgraphics(fig, 'apogee_contour.png', 'Resolution', 300);
% save('apogeeMatrix.mat', 'Z_ft', 'X_fts', 'Y_lb');
