otis_path = "rocket_files/IREC_2025_M6000ST-0.ork";

% Load rocket and sim
otis = openrocket(otis_path);
base_sim = otis.sims("10MPH-TEXAS-36C-(TYP)"); 
opts = base_sim.getOptions();

% Set drogue delay
drogue = otis.component(name = "Streamer");
event = openrocket.get_deploy(drogue, base_sim);
event.setDeployDelay(3);

% Get basemap
lat = opts.getLaunchLatitude;
long = opts.getLaunchLongitude;
width = 2000;
[im, rast, attrib] = flight_basemap(lat, long, width);

% Define wind speeds [m/s] and directions [rad]
mph2mps = 0.44704;
wind_speed_avg =7;
wind_speed_spread = 3;
wind_dirs = 150;
wind_dirs_spread = 50;      % radians

% Set up figure
figure;
mapshow(im, rast); 
hold on;

% Run simulations across wind conditions
nsims = 50;
for i = 1:nsims;

    disp(i)
    % Clone sim to avoid carryover
    sim = otis.sims("10MPH-TEXAS-36C-(TYP)");
    opts = sim.getOptions();
    opts.setLaunchIntoWind(false);
    opts.setWindDirection(deg2rad(wind_dirs + (rand-0.5)*wind_dirs_spread));
    opts.setWindTurbulenceIntensity(0.15);
    opts.setWindSpeedAverage(wind_speed_avg + (rand-0.5)*wind_speed_spread);
    
    % Apply drogue delay again to this sim
    event = openrocket.get_deploy(drogue, sim);
    event.setDeployDelay(3);
    
    % Run and extract data
    openrocket.simulate(sim);
    data = openrocket.get_data(sim);
    
    x = data.("Position East of launch");
    y = data.("Position North of launch");
    z = data.Altitude;
    disp([max(x), max(y), max(z)]);

    
    % Plot trajectory
   
    plot3(x, y, z);

end


xlabel('East [m]');
ylabel('North [m]');
zlabel('Altitude [m]');
view(45, 30);
grid on;
