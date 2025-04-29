% This script will collect all of the data in various scripts for you and collect it
close all;clear; 

% paths to integrations. in the future this should be replaced with a
% matlab project
addpath(genpath("C:\\lmatlib"))
addpath(genpath("C:\lmatlib\sim"));

% open rocket integration intitialize 
otis_path = "C:\\irec-2025-analysis\\IREC_2025_M6000ST-0.ork";
otis = openrocket(otis_path);
sim = otis.sims("0MPH-TEXAS-30C"); %from openrocket
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end

% open rocket integration config
opts = sim.getOptions();

%Monte carlo variables
nSims = 10; % change this to increase number of iterations. higher is better. minimum for any design review is 100 
wind_speed = 4.47; %m/s
wind_speed_spread = 4.47; % m/s
wind_speed_devation = (wind_speed/10);
wind_direction = 45;
temp_spread = 10; % c
temp = opts.getLaunchTemperature;
wind_direction_spread = 360;
time_step = 0.025;
turb = 0.15;
tol         = 0.1;

%conversion factors
m_sTOmph = 2.237136;
meterTofoot = 3.28084;
sTomS = 1/1000;

alt_data = [2,2];

m_kg = 0

cmp = otis.component('name','Adjustable stability weight(s)');

cmp.setOverrideMass(m_kg);
cmp.setComponentMass(m_kg);


data = openrocket.simulate(sim, outputs = "ALL");

data.("Indicated altitude") = pressalt("m", data.("Air pressure"), "Pa") - pressalt("m", data{1, "Air pressure"}, "Pa");

plot((data.("Indicated altitude")))
hold on
plot((data.("Altitude")))
hold off

legend('Indicated Alt','Alt')

amax = max(data.("Altitude"))

imax = max(data.("Indicated altitude"))

alt_data (1,1) = amax;
ald_data (1,2) = imax;



