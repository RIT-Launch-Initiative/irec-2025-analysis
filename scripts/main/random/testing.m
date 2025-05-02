%% LaunchDay_MassLookup.m
clear; close all; clc;

% File paths
orkFilePath = 'rocket_files/IREC_2025_M6000ST-0.ork';

% Available pucks (g)
pucks_g = [1600 800 400 200 100 50 25];

% Temperature and wind grids
tempVals_C   = 20:10:50;   % °C grid
windVals_mph = 2:5:20;    % mph grid

% Nose mass bounds and target
noseMin_kg   = 1;
noseMax_kg   = 2.5;
targetApogee_ft_default = 10100;

tol_ft  = 15;   % apogee tolerance (ft)
maxIter = 20;   % bisection iterations

%% VERIFY OPENROCKET
if isempty(which('net.sf.openrocket.startup.Application'))
    error('OpenRocket classes not found. Run openrocket_setup and restart MATLAB.');
end

%% CONSTANTS & PREALLOC
ft2m   = 0.3048;
mph2ms = 0.44704;
nT = numel(tempVals_C);
nW = numel(windVals_mph);
massChart_kg = NaN(nT,nW);

%% LOAD ROCKET & COMPONENT
otis    = feval('openrocket', orkFilePath);
noseCmp = otis.component('name','Adjustable stability weight(s)');
simObj  = otis.sims("10MPH-TEXAS-36C-(TYP)");

%% CUSTOM ATMOSPHERE SETUP
site    = launchsites("spaceport-midland");
lt      = datetime(2024,06,21,10,21,0,'TimeZone','MST');
air     = atmosphere("gfs","pgrb2.1p00",site.lat,site.lon,lt,minpres=450);
air.TMP = air.TMP + 273.15;                             % °C → K
atmData = air(:,["HGT","PRES","TMP"]);

%% BUILD TEMP × WIND GRID
wb = waitbar(0,'Building grid...');
for kT = 1:nT
    % set ambient temperature for this row (flat profile)
    T_C = tempVals_C(kT);
    T_K = T_C + 273.15;
    atmData.TMP(:) = T_K;

    waitbar(kT/nT, wb, sprintf('Temp %d°C (%d/%d)', T_C, kT, nT));
    for jW = 1:nW
        W_ms = windVals_mph(jW) * mph2ms;
        massChart_kg(kT,jW) = find_mass(otis, simObj, noseCmp, atmData, ...
            W_ms, targetApogee_ft_default, noseMin_kg, noseMax_kg, tol_ft, maxIter, ft2m);
    end
end
close(wb);

%% SHOW HEAT-MAP
figure('Color','w');
imagesc(windVals_mph, tempVals_C, massChart_kg);
set(gca,'YDir','normal','FontSize',24,'GridLineStyle','none');
box on;

% --- greyscale map -------------------------------------------------------
nC   = 256;           % same resolution you used
cmap = gray(nC);      % dark = low, light = high (flipud(gray(nC)) to invert)
colormap(cmap);
% -------------------------------------------------------------------------

xlabel('Wind speed [mph]','FontSize',24);
ylabel('Temperature [°C]','FontSize',24);

% annotate
digits = 3;  fmt = sprintf('%%.%df',digits);
for r = 1:nT
    for c = 1:nW
        val = massChart_kg(r,c);
        if ~isnan(val)
            % pick text color based on cell brightness (mid-point = 0.5)
            normVal = (val-min(massChart_kg(:)))/(max(massChart_kg(:))-min(massChart_kg(:)));
            txtColor = normVal>0.5;   % 0→black, 1→white
            text(windVals_mph(c), tempVals_C(r), sprintf(fmt,val), ...
                 'HorizontalAlignment','center', 'FontSize',16, ...
                 'Color', [txtColor txtColor txtColor]);
        end
    end
end
drawnow;


%% LOOKUP LOOP
while true
    fprintf('\n—--- New lookup (press Enter at temp prompt to quit) —---\n');
    T_user = input(sprintf('Ambient temperature [°C] (%d–%d): ', tempVals_C(1), tempVals_C(end)));
    if isempty(T_user), disp('Done.'); break; end

    W_user = input(sprintf('Average wind speed [mph] (%d–%d): ', windVals_mph(1), windVals_mph(end)));
    if isempty(W_user), disp('Need a wind speed.'); continue; end

    A_user = input(sprintf('Target apogee [ft AGL] (default %d): ', targetApogee_ft_default));
    if isempty(A_user), A_user = targetApogee_ft_default; end

    % update atmosphere for user’s temp
    atmData.TMP(:) = T_user + 273.15;

    reqMass_kg = find_mass(otis, simObj, noseCmp, atmData, W_user*mph2ms, ...
                    A_user, noseMin_kg, noseMax_kg, tol_ft, maxIter, ft2m);

    if isnan(reqMass_kg)
        fprintf('⚠️  Not reachable within %.1f–%.1f kg window.\n', noseMin_kg, noseMax_kg);
        continue;
    end

    [puckList_g,residual_g] = split_into_pucks(reqMass_kg, pucks_g);

    fprintf('\nRequired nose mass: %.3f kg\n', reqMass_kg);
    fprintf('Pack pucks [g]: %s\n', mat2str(puckList_g));
    if residual_g > 0
        fprintf('Residual %d g – bring tape/BBs.\n', residual_g);
    end
end

%% FUNCTIONS
function mass = find_mass(otis, simObj, cmp, atmData, W_ms, target_ft, lo, hi, tol, maxIt, ft2m)
    f_lo = apogee_diff(otis, simObj, cmp, atmData, lo, W_ms, ft2m, target_ft);
    f_hi = apogee_diff(otis, simObj, cmp, atmData, hi, W_ms, ft2m, target_ft);
    if sign(f_lo) == sign(f_hi)
        mass = NaN; return;
    end
    for it = 1:maxIt
        mid   = 0.5 * (lo + hi);
        f_mid = apogee_diff(otis, simObj, cmp, atmData, mid, W_ms, ft2m, target_ft);
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

function diff = apogee_diff(otis, simObj, cmp, atmData, m_kg, W_ms, ft2m, target_ft)
    cmp.setOverrideMass(m_kg);
    cmp.setComponentMass(m_kg);
    opts = simObj.getOptions();
    opts.setWindSpeedAverage(W_ms);
    opts.setWindSpeedDeviation(0);
    opts.setLaunchIntoWind(false);
    opts.setTimeStep(0.05);

    data=otis.simulate(simObj, outputs="ALL");

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