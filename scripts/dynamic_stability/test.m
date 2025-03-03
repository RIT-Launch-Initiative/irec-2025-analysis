%% Clear Workspace and Close Figures
clear; close all; clc;

%% Constants and Unit Conversions
ft_to_m       = 0.3048;           
lbft2_to_kgm2 = 1.35581795;       
oz_to_kg      = 0.0283495;        
in_to_m       = 0.0254;           
in2_to_m2     = 0.00064516;       

%% File Paths and Simulation Names
% Make sure these are MATLAB string scalars (double quotes)
ork_file_path1 = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
sim_name1      = "15MPH-TEXAS-36C-(TYP)";

ork_file_path2 = "C:\irec-2025-analysis\IREC 2024.ork";
sim_name2      = "Spaceport America 0 MPH Case";

addpath(genpath("C:\lmatlib"));

winddirection = 45;
wind_speed = 0;
temperature = 27;
timestep = 0.001;
launchangle = deg2rad(6);

%% === Simulation 1 ===
otis1 = openrocket(ork_file_path1);
sim1  = otis1.sims(sim_name1);
opts1 = sim1.getOptions;
opts1.setWindDirection(winddirection);  
opts1.setWindTurbulenceIntensity(0)
opts1.setWindSpeedAverage(wind_speed);
opts1.setLaunchTemperature(temperature);
opts1.setTimeStep(timestep)

% Adjust rod angle/length to 6, if that's your intention
opts1.setLaunchRodAngle(launchangle); 

openrocket.simulate(sim1);
data1 = openrocket.get_data(sim1);
aoa = rad2deg(data1.('Angle of attack'));

plot(aoa)

