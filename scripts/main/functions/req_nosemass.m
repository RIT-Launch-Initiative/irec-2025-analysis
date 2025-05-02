function [reqMass_kg, puckList_g, residual_g] = req_nosemass(launchTemp, wind_ms)
    % Optional: target apogee (default 10100 ft)
    targetApogee_ft = 10100;

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


    % Simulate and get required mass
    step_kg   = 0.01;
    reqMass_kg = find_mass_brute(otis, simObj, noseCmp, ...
                     wind_ms, targetApogee_ft, noseMin_kg, noseMax_kg, ...
                     step_kg, ft2m, launchTemp);


    if isnan(reqMass_kg)
        puckList_g = [];
        residual_g = NaN;
        return;
    end

    [puckList_g, residual_g] = split_into_pucks(reqMass_kg, pucks_g);
end

function mass = find_mass_brute(otis, simObj, cmp, W_ms, target_ft, ...
                                lo, hi, step, ft2m, launchTemp)

    masses = lo : step : hi;              % e.g. 0 : 0.01 : 2.5
    errs   = zeros(size(masses));         % apogee error for each mass

    for k = 1:numel(masses)
        errs(k) = apogee_diff(otis,simObj,cmp, masses(k), ...
                              W_ms, ft2m, target_ft, launchTemp);
    end

    [~, idx] = min(abs(errs));            % closest to target
    mass     = masses(idx);

    % Optional: refine locally with a second, finer sweep
    % lo2 = max(lo, masses(idx)-step);
    % hi2 = min(hi, masses(idx)+step);
    % mass = find_mass_brute(..., lo2, hi2, step/10, ...);
end


function diff = apogee_diff(otis, simObj, cmp , m_kg, W_ms, ft2m, target_ft,launchTemp)
    opts = simObj.getOptions();
    cmp.setOverrideMass(m_kg);
    cmp.setComponentMass(m_kg);
   
    opts.setWindSpeedAverage(W_ms);
    opts.setLaunchTemperature(launchTemp+273.15);
    opts.setWindSpeedDeviation(0);
    opts.setLaunchIntoWind(false);
    opts.setTimeStep(0.05);

    data=otis.simulate(simObj, outputs="ALL");

    data.("Indicated altitude") = pressalt("m", data.("Air pressure"), "Pa") - pressalt("m", data{1, "Air pressure"}, "Pa");

    diff = max(data.("Indicated altitude"))/ft2m - target_ft;
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


