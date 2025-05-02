function [reqMass_kg, puckList_g, residual_g] = nm_getmass(launchTemp, wind_ms)
%REQ_NOSEMASS  Compute required adjustable nose‑cone ballast to hit target apogee
%   Uses a cost‑function formulation with fminsearch (Nelder‑Mead)
%   rather than root‑finding or brute‑force sweeps.

    % ----- USER‑TUNABLE PARAMETERS -------------------------------------
    targetApogee_ft = 10700;      % desired altitude [ft]
    noseMin_kg      = 0;          % lower mass bound  [kg]
    noseMax_kg      = 2.5;        % upper mass bound  [kg]
    tol_ft          = 10;         % accept if |apogee‑target| ≤ tol
    pucks_g         = [1600 800 400 200 100 50 25];   % discrete weights
    
    orkFilePath     = "rocket_files/IREC_2025_M6000ST-0.ork";
    simName         = "10MPH-TEXAS-36C-(TYP)";        % baseline sim in ORK
    ft2m            = 0.3048;

    % ----- INITIALISE OPENROCKET DOCUMENT ------------------------------
    otis    = feval("openrocket", orkFilePath);
    noseCmp = otis.component('name','Adjustable stability weight(s)');
    simObj  = otis.sims(simName);

    % ----- BUILD COST FUNCTION HANDLE ----------------------------------
    costFun = make_cost_function(otis, simObj, noseCmp, ...
                                 wind_ms, launchTemp, ...
                                 targetApogee_ft, ft2m, ...
                                 noseMin_kg, noseMax_kg);

    % fminsearch options – stop when altitude error < tol_ft
    opts = optimset('Display','iter', ...
                    'TolFun',tol_ft, ...    % altitude error tolerance
                    'TolX',0.002);          % ≈ 2 g mass resolution

    m0 = 0.5*(noseMin_kg + noseMax_kg);     % mid‑range initial guess
    [reqMass_kg, fval] = fminsearch(costFun, m0, opts);

    % ----- POST‑PROCESS -----------------------------------------------
    if fval > tol_ft  % optimizer failed to reach tolerance
        warning('req_nosemass:NoConverge', ...
                'Could not meet apogee tolerance (|err| = %.1f ft)', fval);
        reqMass_kg = NaN;
        puckList_g = [];
        residual_g = NaN;
        return;
    end

    [puckList_g, residual_g] = split_into_pucks(reqMass_kg, pucks_g);
end

%% ------------------------------------------------------------------------
function func = make_cost_function(otis, simObj, cmp, ...
                                   W_ms, launchTemp, ...
                                   target_ft, ft2m, ...
                                   lo, hi)
%MAKE_COST_FUNCTION  Return handle @(m) that gives altitude error [ft]
%   Clamps mass into [lo,hi] so the optimizer cannot wander outside.

    opts = simObj.getOptions();  % capture once – reuse inside cost()
    opts.setWindSpeedAverage(W_ms);
    opts.setWindSpeedDeviation(0);
    opts.setLaunchIntoWind(false);
    opts.setTimeStep(0.05);
    opts.setLaunchTemperature(launchTemp + 273.15);   % °C → K

    func = @cost;
    function err = cost(x)
        % Clamp mass
        m = min(max(x(1), lo), hi);
        cmp.setOverrideMass(m);
        cmp.setComponentMass(m);

        data = otis.simulate(simObj, 'outputs','ALL');
        apogee_ft = max(data.Altitude)/ft2m;
        err = abs(apogee_ft - target_ft);  % |error| for Nelder‑Mead
    end
end

%% ------------------------------------------------------------------------
function [combo, res] = split_into_pucks(req_kg, pucks)
%SPLIT_INTO_PUCKS  Greedy decomposition of required kg into puck sizes
    remaining = round(req_kg * 1000);  % grams
    combo = [];
    for p = pucks
        while remaining >= p
            combo(end+1) = p; %#ok<AGROW>
            remaining = remaining - p;
        end
    end
    res = remaining;
end
