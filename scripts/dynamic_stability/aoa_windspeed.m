%% Clear Workspace and Close Figures
clear; close all; clc;

%% Constants and Unit Conversions  (kept for completeness)
ft_to_m       = 0.3048;           
lbft2_to_kgm2 = 1.35581795;       
oz_to_kg      = 0.0283495;        
in_to_m       = 0.0254;           
in2_to_m2     = 0.00064516;       

%% File Paths and Simulation Names
addpath(genpath("C:\lmatlib"));

ork_file_path1 = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
sim_name1      = "15MPH-TEXAS-36C-(TYP)";

ork_file_path2 = "C:\irec-2025-analysis\IREC 2024.ork";
sim_name2      = "Spaceport America 0 MPH Case";

%% Shared Parameters
wind_speeds   = 0:5:20;         % mph – change as required
winddirection = 45;             % degrees
temperature   = 27;             % °C
timestep      = 0.05;          % s
launchangle   = 6;              % degrees

%% Pre‑allocate result arrays
maxAoA1 = nan(size(wind_speeds));
maxAoA2 = nan(size(wind_speeds));

%% Load rocket files once
otis1 = openrocket(ork_file_path1);
sim1  = otis1.sims(sim_name1);
opts1 = sim1.getOptions;
opts1.setWindDirection(winddirection);
opts1.setWindTurbulenceIntensity(0);
opts1.setLaunchTemperature(temperature);
opts1.setTimeStep(timestep);
opts1.setLaunchRodAngle(launchangle);

otis2 = openrocket(ork_file_path2);
sim2  = otis2.sims(sim_name2);
opts2 = sim2.getOptions;
opts2.setWindDirection(winddirection);
opts2.setWindTurbulenceIntensity(0);
opts2.setLaunchTemperature(temperature);
opts2.setTimeStep(timestep);
opts2.setLaunchRodAngle(launchangle);

%% Run sweep over wind speeds
for k = 1:numel(wind_speeds)
    ws = wind_speeds(k);

    % --- Simulation 1 ---
    opts1.setWindSpeedAverage(ws);
    openrocket.simulate(sim1);
    data1 = openrocket.get_data(sim1);

    % filter LAUNCHROD → BURNOUT and grab max AoA
    range1 = timerange(eventfilter("LAUNCHROD"), eventfilter("BURNOUT"), "openleft");
    aoa1   = rad2deg(max(data1(range1, :).('Vertical orientation (zenith)')));
    maxAoA1(k) = aoa1;

    % --- Simulation 2 ---
    opts2.setWindSpeedAverage(ws);
    openrocket.simulate(sim2);
    data2 = openrocket.get_data(sim2);

    range2 = timerange(eventfilter("LAUNCHROD"), eventfilter("BURNOUT"), "openleft");
    aoa2   = rad2deg(max(data2(range2, :).('Vertical orientation (zenith)')));
    maxAoA2(k) = aoa2;
end

%% Plot results
figure('Name','Max Angle‑of‑Attack vs Wind Speed');
plot(wind_speeds, maxAoA1, '-o', 'LineWidth',1.5, 'DisplayName', sim_name1); hold on;
plot(wind_speeds, maxAoA2, '-s', 'LineWidth',1.5, 'DisplayName', sim_name2);
xlabel('Wind Speed (mph)');
ylabel('Maximum AOA between LAUNCHROD and BURNOUT (deg)');
title('Maximum Angle‑of‑Attack vs Wind Speed');
legend('Location','best');
grid on;
