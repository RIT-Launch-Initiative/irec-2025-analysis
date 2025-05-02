function [reqMass_kg, puckList_g, residual_g] = req_nosemass(launchTemp, wind_mph, varargin)
    % Optional: target apogee (default 10100 ft)
    targetApogee_ft = 10100;
    if nargin == 3
        targetApogee_ft = varargin{1};
    end

    % Parameters
    orkFilePath = 'rocket_files/IREC_2025_M6000ST-0.ork';
    noseMin_kg = 0;
    noseMax_kg = 2.5;
    tol_ft = 10;
    maxIter = 20;
    pucks_g = [1600 800 400 200 100 50 25];
    ft2m = 0.3048; mph2ms = 0.44704;


    % Load OpenRocket setup
    otis    = feval('openrocket', orkFilePath);
    noseCmp = otis.component('name','Adjustable stability weight(s)');
    simObj  = otis.sims("10MPH-TEXAS-36C-(TYP)");

    % setup atm
    air     = load("rocket_files/midland_atmosphere.mat").airdata;
    atmData = air(:, ["HGT","PRES","TMP"]);             % pass this to simulate
    atmData.TMP = atmData.TMP + 273.15;


    % Simulate and get required mass
    reqMass_kg = find_mass(otis, simObj, noseCmp, atmData, wind_mph*mph2ms, ...
                    targetApogee_ft, noseMin_kg, noseMax_kg, tol_ft, maxIter, ft2m,launchTemp);

    if isnan(reqMass_kg)
        puckList_g = [];
        residual_g = NaN;
        return;
    end

    [puckList_g, residual_g] = split_into_pucks(reqMass_kg, pucks_g);
end

%% FUNCTIONS
function mass = find_mass(otis, simObj, cmp, atmData, W_ms, target_ft, lo, hi, tol, maxIt, ft2m,launchTemp)
    f_lo = apogee_diff(otis, simObj, cmp, atmData, lo, W_ms, ft2m, target_ft,launchTemp);
    f_hi = apogee_diff(otis, simObj, cmp, atmData, hi, W_ms, ft2m, target_ft,launchTemp);
    if sign(f_lo) == sign(f_hi)
        mass = NaN; return;
    end
    for it = 1:maxIt
        mid   = 0.5 * (lo + hi);
        f_mid = apogee_diff(otis, simObj, cmp, atmData, mid, W_ms, ft2m, target_ft,launchTemp);
        if abs(f_mid) < tol || (hi - lo) < 0.005
            mass = mid; return;
        end
        if sign(f_mid) == sign(f_lo)
            lo   = mid; f_lo = f_mid;
        else
            hi   = mid; f_hi = f_mid;
        end
    end
    mass = mid;
end

function diff = apogee_diff(otis, simObj, cmp, atmData, m_kg, W_ms, ft2m, target_ft,launchTemp)
    cmp.setOverrideMass(m_kg);
    cmp.setComponentMass(m_kg);
    opts = simObj.getOptions();
    opts.setWindSpeedAverage(W_ms);
    opts.setLaunchTemperature(launchTemp+273.15);
    opts.setWindSpeedDeviation(0);
    opts.setLaunchIntoWind(false);
    opts.setTimeStep(0.05);

    data = otis.simulate(simObj, 'outputs','Air pressure','atmos',atmData);

    h = pressalt("m", data.("Air pressure"), "Pa") ...
      - pressalt("m", data{1,"Air pressure"}, "Pa");

    diff = max(h)/ft2m - target_ft;
end

function [combo, res] = split_into_pucks(req_kg, pucks)
    remaining = round(req_kg * 1000);
    combo = [];
    for p = pucks
        while remaining >= p
            combo(end+1) = p; %#ok<AGROW>
            remaining = remaining - p;
        end
    end
    res = remaining;
end


