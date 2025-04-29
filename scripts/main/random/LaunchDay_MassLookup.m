clear; close all; clc;

orkFilePath = 'C:/irec-2025-analysis/IREC_2025_M6000ST-0.ork';
lmatlibPath = 'C:/lmatlib';

% define the avail. pucks
pucks_g = [1600 800 400 200 100 50 25];% grams, descending

tempVals_C   = 20:1:40;   % °C grid
windVals_mph = 3:1:20;    % mph grid
noseMin_kg   = 1;
noseMax_kg   = 2.5;
targetApogee_ft_default = 10100; % default apogee

tol_ft  = 15;% apogee tolerance
maxIter = 20;% bisection iterations

%% VERIFY OPENROCKET ON STATIC PATH 
if isempty(which('net.sf.openrocket.startup.Application'))
    error(['OpenRocket classes not found. Run openrocket_setup(<dir>) and *restart MATLAB*.']);
end

%% PATHS
addpath(genpath(lmatlibPath));
addpath(genpath(fullfile(lmatlibPath,'sim')));

%% CONSTANTS & PREALLOC
ft2m   = 0.3048;  mph2ms = 0.44704;

nT = numel(tempVals_C); nW = numel(windVals_mph);
massChart_kg = NaN(nT,nW);

%% LOAD ROCKET & COMPONENT
otis = feval('openrocket', orkFilePath);
noseCmp = otis.component('name','Adjustable stability weight(s)');
simObj  = otis.sims("10MPH-TEXAS-36C-(TYP)");

%% BUILD TEMP × WIND GRID
wb = waitbar(0,'Building Temp × Wind lookup grid...');
for kT = 1:nT
    waitbar(kT/nT, wb, sprintf('Temp %d°C (%d of %d)', ...
           tempVals_C(kT), kT, nT));
    T_K = tempVals_C(kT) + 273.15;
    for jW = 1:nW
        W_ms = windVals_mph(jW) * mph2ms;
        massChart_kg(kT,jW) = find_mass(T_K,W_ms, ...
            targetApogee_ft_default,noseMin_kg,noseMax_kg, ...
            tol_ft,maxIter,ft2m,noseCmp,simObj);
    end
end
close(wb)

%% SHOW HEAT-MAP 
figure('Color','w'); imagesc(windVals_mph,tempVals_C,massChart_kg);
set(gca,'YDir','normal'); grid on; box on; colormap(turbo);
xlabel('Wind speed [mph]'); ylabel('Midland temp [°C]');
digits = 3;                       % how many decimals you want
fmt    = sprintf('%%.%df',digits);  % e.g. '%.2f', '%.3f', …

for r = 1:nT
    for c = 1:nW
        if ~isnan(massChart_kg(r,c))
            text(windVals_mph(c), tempVals_C(r), ...
                 sprintf(fmt, massChart_kg(r,c)), ...
                 'HorizontalAlignment','center', ...
                 'FontSize',8,'Color','k');
        end
    end
end

drawnow;

%% LOOKUP LOOP 
while true
    fprintf('\n—--- New lookup (press Enter at temp prompt to quit) —---\n');
    T_user = input(sprintf('Ambient temperature [°C] (%d–%d): ', ...
                   tempVals_C(1), tempVals_C(end)));
    if isempty(T_user), disp('Done.'); break; end

    W_user = input(sprintf('Average wind speed [mph] (%d–%d): ', ...
                   windVals_mph(1), windVals_mph(end)));
    if isempty(W_user), disp('Need a wind speed.'); continue; end

    A_user = input(sprintf('Target apogee [ft AGL] (default %d): ', ...
                   targetApogee_ft_default));
    if isempty(A_user), A_user = targetApogee_ft_default; end

    reqMass_kg = find_mass(T_user+273.15, W_user*mph2ms, A_user, ...
                  noseMin_kg,noseMax_kg,tol_ft,maxIter,ft2m,noseCmp,simObj);

    if isnan(reqMass_kg)
        fprintf('⚠️  Not reachable within %.1f–%.1f kg window.\n', ...
                noseMin_kg,noseMax_kg);
        continue
    end

    [puckList_g,residual_g] = split_into_pucks(reqMass_kg,pucks_g);

    fprintf('\nRequired nose mass: %.3f kg\n', reqMass_kg);
    fprintf('Pack pucks [g]: %s\n', mat2str(puckList_g));
    if residual_g>0, fprintf('Residual %d g – bring tape/BBs.\n', residual_g); end
end

%% FUNCTIONS 
function mass = find_mass(T_K,W_ms,target_ft,lo,hi,tol,maxIt,ft2m,cmp,simObj)
    f=@(m) apogee_diff(m,T_K,W_ms,ft2m,target_ft,cmp,simObj);
    f_lo=f(lo); f_hi=f(hi); if sign(f_lo)==sign(f_hi), mass=NaN; return; end
    for it=1:maxIt
        mid=0.5*(lo+hi); f_mid=f(mid);
        if abs(f_mid)<tol || (hi-lo)<0.005, mass=mid; return; end
        if sign(f_mid)==sign(f_lo), lo=mid; f_lo=f_mid; else, hi=mid; f_hi=f_mid; end
    end
    mass=mid;
end

function diff = apogee_diff(m_kg,T_K,W_ms,ft2m,target_ft,cmp,simObj)
    cmp.setOverrideMass(m_kg); cmp.setComponentMass(m_kg);
    opts=simObj.getOptions();
    opts.setWindSpeedAverage(W_ms); opts.setWindSpeedDeviation(0);
    opts.setLaunchIntoWind(false); opts.setTimeStep(0.05); opts.setLaunchTemperature(T_K);
    data=openrocket.simulate(simObj,'outputs','Altitude');
    diff=max(data.Altitude)/ft2m - target_ft;
end

function [combo,res] = split_into_pucks(req_kg,pucks)
    remaining = round(req_kg*1000); combo=[];
    for p=pucks
        while remaining>=p
            combo(end+1)=p; %#ok<AGROW>
            remaining = remaining - p;
        end
    end
    res = remaining;
end
