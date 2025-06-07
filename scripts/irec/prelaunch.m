%% PRE-LAUNCH DAY ROCKET NOSE MASS OPTIMIZATION

% Housekeeping
clear;
close all;
clc;


% --- Launch & Site ---
rocket_file = "rocket_files\IREC_2025_M6000ST-0.ork";
sim_name    = "10MPH-TEXAS-36C-(TYP)";
site_name   = "spaceport-midland";
nose_cmp_name = 'Adjustable stability weight(s)'; % Name of the adjustable mass component in OpenRocket

% --- Time Window ---
% Define the center of your potential launch window
nominal_launch_time = datetime(2025, 06, 09, 10, 00, 00, TimeZone = "-06:00");

% Define the time range to analyze around the nominal time (e.g., ±3 hours)
time_window_hours = 0;
% Define the interval for analysis (e.g., check weather every 1 hour)
time_step_hours = 1;

% --- Optimization Target ---
target_apogee_ft = 10700;       % Desired apogee [ft]
mass_min_kg      = 0.0;         % Lower bound for nose mass search [kg]
mass_max_kg      = 2.5;         % Upper bound for nose mass search [kg]
tolerance_ft     = 10;          % Optimizer stops if |apogee_error| < tolerance_ft

% --- Puck System (for discrete mass calculation, optional) ---
pucks_g = [1645 795 390 195 95 45]; % Available discrete puck masses [grams]


% Create the array of datetime objects to be analyzed
launch_window = nominal_launch_time + hours(-time_window_hours:time_step_hours:time_window_hours);

% Load rocket and simulation details
otis = openrocket(rocket_file);
sim  = otis.sims(sim_name);
site = launchsites(site_name);
nose_component = otis.component('name', nose_cmp_name);
ft2m = 0.3048; % Conversion factor

num_sims = numel(launch_window);
optimal_masses_kg = nan(1, num_sims);

site = launchsites("spaceport-midland");

for i = 1:num_sims
    current_time = launch_window(i);
    
    % --- FIX starts here ---
    % Fetch weather data for the CURRENT time step inside the loop
    waitbar_msg = sprintf('Fetching weather for %s...', string(current_time));

    airdata = atmosphere("gfs", "pgrb2.1p00", site.lat, site.lon, current_time, ...
    minpres = 450, cache = "airdata.mat");    
    % Celcius to Kelvin
    airdata.TMP = airdata.TMP + 273.15;
       
    
    req_mass_kg = nm_getmass(current_time);
    
    optimal_masses_kg(i) = req_mass_kg;
    
    if ~isnan(req_mass_kg)
        fprintf('Success. Mass = %.3f kg\n', req_mass_kg);
    else
        fprintf('Failed.\n');
    end
end

