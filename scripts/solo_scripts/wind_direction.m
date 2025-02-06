set(groot, "DefaultAxesNextPlot", "add");
clear; close all;

addpath(genpath("C:\lmatlib\sim"));

%% Basic plots


otis_path = "C:\\irec-2025-analysis\\IREC_2025_M6000ST-0.ork"; %pfullfile("samples", "data", "OTIS.ork");
if ~isfile(otis_path)
    error("No document '%s' found for OR sample. Make sure [samples/] is the current working folder or otherwise on the PATH.", otis_path);
end


otis = openrocket(otis_path);
sim = otis.sims(1); % get simulation by number

drogue = otis.component(name = "Streamer"); % get streamer 
event = openrocket.get_deploy(drogue, sim); % get event for drogue chute
event.setDeployDelay(3); % 3-second drogue delay

openrocket.simulate(sim); % execute simulation
data = openrocket.get_data(sim); % get all of the simulation's outputs
% equivalently, data = openrocket.simulate(sim, outputs = "ALL") will do the same thing



%% Monte Carlo simulations
n_sims = 500;
launch_spread = 4;
wind_speed_spread = 15;
wind_angle_spread = 45;

otis = openrocket(otis_path);
sim = otis.sims("15MPH-TEXAS-36C-(TYP)");
opts = sim.getOptions();
opts.setWindTurbulenceIntensity(0.15);
opts.setLaunchRodDirection(deg2rad(60));
opts.setTimeStep(0.05); % lower rate to improve performacne

launch_angle = opts.getLaunchRodAngle();
wind_speed = opts.getWindSpeedAverage();

data_out = cell(1, n_sims);
for i = 1:length(data_out)
    opts.setLaunchRodAngle(deg2rad(launch_angle + (rand()-0.5)*launch_spread));
    opts.setLaunchIntoWind(false);
    opts.setWindDirection(-opts.getLaunchRodDirection + ...
        deg2rad((rand()-0.5)*wind_angle_spread));
    opts.setWindSpeedAverage(wind_speed + (rand()-0.5)*wind_speed_spread);

    data_out{i} = openrocket.simulate(sim, outputs = "ALL");
    disp(i)
end

figure(name = "Landing point spread");
plot(0, 0, "+r", LineWidth = 2);
for i = 1:length(data_out)
    data = data_out{i};
    hit_data = data(eventfilter("GROUND_HIT"), :);
    plot(hit_data.("Position East of launch"), hit_data.("Position North of launch"), "xk");
end
xlabel("East [m]"); ylabel("North [m]");
title(sprintf("Landing point spread for %s\n Rod \\pm %.1f deg, Wind \\pm %.1f m/s at \\pm %.0f deg", ...
    sim.getName(), launch_spread/2, wind_speed_spread/2, wind_angle_spread/2))

