% Post launch recreation 

clear; close all; clc;

% setup
rocket_file = "rocket_files\IREC_2025_M6000ST-0.ork";
sim_name    = "10MPH-TEXAS-36C-(TYP)";
site_name   = "spaceport-midland";
nose_cmp_name = 'Adjustable stability weight(s)';
otis = openrocket(rocket_file);
sim  = otis.sims("10MPH-TEXAS-36C-(TYP)");
site = launchsites(site_name);
opts = sim.getOptions();
launch_nose_mass = 1035;


% time setup
ref_time = datetime('now','TimeZone','-05:00') - hours(1);
nominal_launch_time = datetime(2025,06,11,13,0,0,'TimeZone','-05:00');



ft2m = 0.3048;

% custom atm setup
% airdata = atmosphere("hrrr","wrfprsf",site.lat,site.lon,nominal_launch_time, ...
%                      minpres=450,cache=matfile);

air     = load("scripts\irec\airdata_cache\hrrr_wed_post\airdata_20250611_1300.mat").airdata;
airdata = air(:, ["HGT","PRES","TMP","UGRD","VGRD"]);             % pass this to simulate
airdata.TMP = airdata.TMP + 273.15;



launch_temp_K = interp1(airdata.HGT,airdata.TMP,site.alt,'linear','extrap');
u = interp1(airdata.HGT,airdata.UGRD,site.alt,'linear','extrap');
v = interp1(airdata.HGT,airdata.VGRD,site.alt,'linear','extrap');

wind_dir = rad2deg(unwrap(atan2(u,v)));
wind_speed_ms = hypot(v,u);
opts.setLaunchIntoWind(true);
opts.setWindDirection(deg2rad(wind_dir))

fprintf('\n U comp %0.1f, V comp %0.1f',u,v);

fprintf(' %s  %.1f °C  %.1f m/s  ',nominal_launch_time,launch_temp_K-273.15,wind_speed_ms);
    
% simulate
data      = otis.simulate(sim,'outputs','Altitude', ...
             atmos=airdata(:,["HGT","PRES","TMP","UGRD","VGRD"]));


apogee_ft = max(data.Altitude)/ft2m





