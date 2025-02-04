clear; close all; 
%% Monte Carlo simulations
n_sims = 20;
launch_spread = 4;
wind_speed_spread = 5;
wind_angle_spread = 60;

ork_file_path = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
addpath(genpath("C:\lmatlib\sim"));

% Name of the OpenRocket simulation to run
sim_name = "15MPH-TEXAS-36C-(TYP)";

otis = openrocket(ork_file_path);
sim = otis.sims(sim_name);
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
    opts.randomizeSeed
end

figure(name = "Landing point spread");
plot(0, 0, "+k", LineWidth = 2);
for i = 1:length(data_out)
    data = data_out{i};
    hit_data = data(eventfilter("GROUND_HIT"), :);
    plot(hit_data.("Position East of launch"), hit_data.("Position North of launch"), "xk");
    disp(hit_data.("Position East of launch"));
    disp(hit_data.("Position North of launch"));

end
xlabel("East [m]"); ylabel("North [m]");
title(sprintf("Landing point spread for %s\n Rod \\pm %.1f deg, Wind \\pm %.1f m/s at \\pm %.0f deg", ...
    sim.getName(), launch_spread/2, wind_speed_spread/2, wind_angle_spread/2))