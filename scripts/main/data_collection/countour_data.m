%% LaunchDay_MassGrid.m
clear; close all; clc;

% File paths
orkFilePath = 'rocket_files/IREC_2025_M6000ST-0.ork';

% Grid values
tempVals_C   = 20:1:40;   % °C
windVals_mph = 2:1:20;    % mph

% Constants
noseMin_kg = 0;
noseMax_kg = 2.5;
targetApogee_ft = 10100;
tol_ft = 10;
maxIter = 20;

%% Load rocket and components
otis    = feval('openrocket', orkFilePath);
noseCmp = otis.component('name','Adjustable stability weight(s)');
simObj  = otis.sims("10MPH-TEXAS-36C-(TYP)");

%% CUSTOM ATMOSPHERE SETUP
% pull GFS‐based profile instead of the default std atmosphere
air     = load("rocket_files/midland_atmosphere.mat").airdata;
atmData = air(:, ["HGT","PRES","TMP"]);             % pass this to simulate
atmData.TMP = atmData.TMP + 273.15;


%% Grid generation
ft2m = 0.3048; mph2ms = 0.44704;
nT = numel(tempVals_C); nW = numel(windVals_mph);
massChart_kg = NaN(nT,nW);

wb = waitbar(0,'Initializing...');

for kT = 1:nT
    T_K = tempVals_C(kT) + 273.15;
    atmData.TMP(:) = T_K;
    waitbar(kT/nT, wb, sprintf('Temp %d°C (%d/%d)', tempVals_C(kT), kT, nT));

    for jW = 1:nW
        W_ms = windVals_mph(jW) * mph2ms;
        massChart_kg(kT,jW) = nm_opt_func(otis, simObj, noseCmp, atmData, ...
            W_ms, targetApogee_ft, noseMin_kg, noseMax_kg, tol_ft, maxIter, ft2m);
    end
end
close(wb);



nm_contour;  % Assumes this reads massChart_kg and plots it
