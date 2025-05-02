% ==============================================================
%  NOSE MASS OPTIMIZER + HEAT-MAP (OpenRocket+MATLAB, FMINSEARCH)
%  Combines “tune_nose_mass.m” and the Temp×Wind heat-map script.
%  • Enter a *single* set of launch conditions  → optimizes nose mass
%  • Give *vectors* of temps / winds           → builds heat-map grid
%  • Uses FMINSEARCH everywhere
%  • Can save the modified .ork file
% ==============================================================

clear; close all; clc;

%% ---------- USER SETTINGS ------------------------------------
orkFilePath   = "C:/irec-2025-analysis/IREC_2025_M6000ST-0.ork";
lmatlibPath   = "C:/lmatlib";

siteName      = "spaceport-midland";        % launch site ID (launchsites)
launchTime    = datetime(2024,06,21,10,21,0,'TimeZone','MST');

% Temperature [°C] and wind-speed [mph].
% • Scalars  → single-point optimisation
% • Vectors  → grid & heat-map
tempVals_C    = 20:1:40;         % e.g. 25 for single run, 20:1:40 for grid
windVals_mph  = 3:1:20;          % e.g. 8  for single run, 3:1:20  for grid

targetApogee_ft = 10100;         % desired apogee AGL
massGuess_kg    = 1.6;           % starting point for FMINSEARCH

noseMassMin_kg  = 0.8;           % for pucks/tape warning only
noseMassMax_kg  = 3.0;

% Save OpenRocket file after single-point run?
saveOR = true;
saveORPath = "C:/irec-2025-analysis/IREC_2025_M6000ST-OPT.ork";

% Available BB “pucks” (for packing the nose weight)
pucks_g = [1600 800 400 200 100 50 25];     % grams, descending

%% ---------- PREP ENVIRONMENT ---------------------------------
% Verify OpenRocket Java classes
if isempty(which('net.sf.openrocket.startup.Application'))
    error(['OpenRocket classes not found. Run openrocket_setup(<dir>) and *restart MATLAB*.']);
end

addpath(genpath(lmatlibPath));
addpath(genpath(fullfile(lmatlibPath,'sim')));

ft2m   = 0.3048;
mph2ms = 0.44704;

%% ---------- LOAD ROCKET & COMPONENT --------------------------
otis   = openrocket(orkFilePath);
cmp    = otis.component('name','Adjustable stability weight(s)');
simObj = otis.sims("10MPH-TEXAS-36C-(TYP)");     % baseline sim

%% ---------- SINGLE-POINT OR GRID? ----------------------------
isGrid = numel(tempVals_C) > 1 || numel(windVals_mph) > 1;

if ~isGrid
    % ===== SINGLE LAUNCH CONDITION =====
    T_C  = tempVals_C(1);
    W_mph= windVals_mph(1);

    [m_opt, apo_ft] = optimize_nose_mass(T_C,W_mph,massGuess_kg,...
                             targetApogee_ft,cmp,simObj);

    fprintf('\nOptimised nose mass : %.3f kg  →  %.1f ft AGL\n', m_opt, apo_ft);
    [puckList_g,residual_g] = split_into_pucks(m_opt,pucks_g);

    fprintf('Pack pucks [g]      : %s\n', mat2str(puckList_g));
    if residual_g>0
        fprintf('Residual            : %d g – bring tape/BBs.\n', residual_g);
    end

    if saveOR
        cmp.setComponentMass(m_opt);
        otis.save(saveORPath);
        fprintf('Modified .ork saved to: %s\n', saveORPath);
    end

else
    % ===== GRID / HEAT-MAP =====
    nT = numel(tempVals_C); nW = numel(windVals_mph);
    massChart_kg   = NaN(nT,nW);
    apogeeChart_ft = NaN(nT,nW);

    wb = waitbar(0,'Building Temp × Wind optimisation grid...');
    for kT = 1:nT
        waitbar(kT/nT,wb,sprintf('Temp %.1f °C  (%d/%d)', ...
               tempVals_C(kT),kT,nT));
        for jW = 1:nW
            [m_opt, apo_ft] = optimize_nose_mass( ...
                    tempVals_C(kT), windVals_mph(jW), massGuess_kg, ...
                    targetApogee_ft, cmp, simObj);

            massChart_kg(kT,jW)   = m_opt;
            apogeeChart_ft(kT,jW) = apo_ft;
        end
    end
    close(wb)

    % ----- Display heat-map (nose mass) -----
    figure('Color','w'); imagesc(windVals_mph,tempVals_C,massChart_kg);
    set(gca,'YDir','normal'); grid on; box on; colormap(turbo);
    xlabel('Wind speed [mph]'); ylabel('Midland temperature [°C]');
    title('Optimised nose-cone mass [kg]');

    for r = 1:nT
        for c = 1:nW
            if ~isnan(massChart_kg(r,c))
                text(windVals_mph(c),tempVals_C(r), ...
                     sprintf('%.2f',massChart_kg(r,c)), ...
                     'HorizontalAlignment','center','FontSize',8);
            end
        end
    end
    drawnow;
end

%% ---------- FUNCTIONS ----------------------------------------
function [m_opt, apogee_ft] = optimize_nose_mass(T_C,W_mph,m0,target_ft,cmp,simObj)
    % Uses FMINSEARCH to minimise squared apogee error
    mph2ms = 0.44704; ft2m = 0.3048;
    W_ms   = W_mph * mph2ms;
    T_K    = T_C   + 273.15;

    cost = @(m) (fly(m) / ft2m - target_ft).^2;
    m_opt = fminsearch(cost, m0, optimset('Display','off'));
    apogee_ft = fly(m_opt) / ft2m;

    function apo_m = fly(m)
        cmp.setOverrideMass(m); cmp.setComponentMass(m);
        opts = simObj.getOptions();
        opts.setWindSpeedAverage(W_ms); opts.setWindSpeedDeviation(0);
        opts.setLaunchIntoWind(false);
        opts.setTimeStep(0.05);
        opts.setLaunchTemperature(T_K);
        data = openrocket.simulate(simObj,'outputs','Altitude');
        apo_m = max(data.Altitude);
    end
end

function [combo,res] = split_into_pucks(req_kg,pucks)
    remaining = round(req_kg*1000); combo=[];
    for p = pucks
        while remaining >= p
            combo(end+1) = p; %#ok<AGROW>
            remaining    = remaining - p;
        end
    end
    res = remaining;
end
