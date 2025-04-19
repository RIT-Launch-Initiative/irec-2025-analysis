clear all; close all; clc;

% --- OpenRocket simulation setup ---
ork_file_path1 = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
sim_name1 = "15MPH-TEXAS-36C-(TYP)";
time_limit = 24; % seconds

otis1 = openrocket(ork_file_path1);
sim1  = otis1.sims(sim_name1);
opts1 = sim1.getOptions;
opts1.setWindDirection(45);  
opts1.setWindTurbulenceIntensity(10);
opts1.setWindSpeedAverage(6.67);
opts1.setWindSpeedDeviation(1);
opts1.setLaunchTemperature(27);
opts1.setTimeStep(0.001);
opts1.setLaunchRodAngle(6); 

openrocket.simulate(sim1);
data1 = openrocket.get_data(sim1);

% Data filtering: LAUNCHROD to APOGEE
data_range1 = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
data1 = data1(data_range1, :);

% Shift rod exit to t=0
time_flight1 = seconds(data1.Time - data1.Time(1));
valid_1 = (time_flight1 <= time_limit);
time_flight1 = time_flight1(valid_1);
aoa1_rad = data1.('Pitch rate')(valid_1);


% --- CRUD Camera data ---
crud_path = 'C:\irec-2025-analysis\scripts\flight-reanalysis\recovered_data\CRUD_Camera.gcsv';
data2 = import_runcam_gcsv(crud_path);

N = height(data2);
timeVec2 = (0:0.001:(N-1)*0.001)';

% define window
t_min = 239;
t_max = 250;
idx = timeVec2 >= t_min & timeVec2 <= t_max;
time_flight2 = timeVec2(idx) - t_min;  % shift to start at zero
ry2 = data2.ry(idx);

% --- Overlapping plots ---
figure;
yyaxis left
plot(time_flight1, aoa1_rad, 'b-', 'LineWidth', 1.5);
ylabel('OpenRocket Pitch Rate (°/s)');
xlabel('Time since rod exit (s)');

yyaxis right
plot(time_flight2, ry2, 'r--', 'LineWidth', 1.5);
ylabel('CRUD Camera r_y (°/s)');

grid on;
title('Overlapped Pitch Rate Data');
legend('OpenRocket Simulation', 'CRUD Camera Data');
