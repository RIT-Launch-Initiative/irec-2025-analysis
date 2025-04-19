clear;

reload_forecast = false;
reload_data = false;
cache = matfile(pfullfile("scripts", "omen-flight-analysis", "info.mat"), Writable = true);

c_to_k = 273.15;
Pa_per_mbar = 100;

launch.lat = 32.93997397890036;
launch.lon = -106.91167077409287;
launch_time = datetime(2024, 06, 31, 10, 20, 00, TimeZone = -hours(4));

landing.lat = 32.940278; 
landing.lon = -106.897861;

richie.lat = 32.950861; 
richie.lon = -106.899222;

if reload_data || isempty(whos(cache, "flight_data"))
    data_file = pfullfile("scripts", "omen-flight-analysis", "recovered_data", ...
        "OMEN_RRC3_Primary.csv");
    flight_data = import_rrc3(data_file);
    cache.flight_data = flight_data;
else
    flight_data = cache.flight_data;
end

if reload_data || isempty(whos(cache, "aero_data"))
    data_file = pfullfile("scripts", "omen-flight-analysis", "OMEN_RA2_Aerodata.CSV");
    aero_data = import_rasaero_aerodata(data_file);
    cache.aero_data = aero_data;
else
    aero_data = cache.aero_data;
end

aero_table = array2table([aero_data.mach, aero_data.pick{"aoa", 0, "field", "CD"} ], ...
    VariableNames = ["MACH", "DRAG"]);


if reload_forecast || isempty(whos(cache, "air_data"));
    hrrr_10h_fcst = ncep.fcst("hrrr", "wrfprsf", launch_time - hours(10), launch_time);
    atmos = atmosphere.from_ncep(hrrr_10h_fcst, ...
        lats = launch.lat + [-1 1], lons = launch.lon + [-1 1]);
    aircol = atmos.aircolumn(launch.lat, launch.lon, launch_time);
    air_data = table;
    air_data.PRES = str2double(extract(aircol.layer, digitsPattern));
    air_data{:, ["HGT", "TMP", "UGRD", "VGRD"]} = ...
        double(aircol.pick{"field", ["HGT", "TMP", "UGRD", "VGRD"]});
    % HGT stays in ASL because AbstractSimulationStepper uses ASL for all atmospheric data
    air_data.PRES = air_data.PRES * Pa_per_mbar;
    air_data.TMP = air_data.TMP + c_to_k;
    cache.air_data = air_data;
else 
    air_data = cache.air_data;
end

launch_alt = 1388; % [m ASL] from OpenMeteo topography query
ground_data = interp1(air_data.HGT, air_data{:, ["PRES", "TMP", "UGRD", "VGRD"]}, launch_alt);
launch_pres = ground_data(1); % [Pa]
launch_temp = ground_data(2); % [K]

launch_wdir = pi/2 - atan2(ground_data(2), ground_data(1)); % [rad] CW from North
launch_wvel = vecnorm(ground_data(3:4)); % [m/s]

ork_file = pfullfile("IREC 2024.ork");
omen = openrocket(ork_file);

sim = omen.sims("MATLAB");
opts = sim.getOptions();
opts.setLaunchAltitude(launch_alt); 
opts.setLaunchIntoWind(false);
opts.setLaunchRodDirection(deg2rad(90 + 60)); % [rad] CW from North (estimated from video)
opts.setLaunchRodAngle(deg2rad(5)); % [rad] from vertical (measured onsite)
opts.setLaunchLatitude(launch.lat);
opts.setLaunchLongitude(launch.lon);
opts.setISAAtmosphere(false);
opts.setLaunchTemperature(launch_temp);
opts.setLaunchPressure(launch_pres); 
opts.setWindSpeedAverage(launch_wvel);
opts.setWindDirection(launch_wdir);
opts.setWindSpeedDeviation(0);
opts.setTimeStep(0.01);

baseline_data = omen.simulate(sim, outputs = "ALL");
atmos_data = omen.simulate(sim, outputs = "ALL", atmos = air_data(:, ["HGT", "TMP", "PRES"]));
wind_data = omen.simulate(sim, outputs = "ALL", wind = air_data(:, ["HGT", "UGRD", "VGRD"]));
drag_data = omen.simulate(sim, outputs = "ALL", drag = aero_table);
all_data = omen.simulate(sim, outputs = "ALL", ...
    wind = air_data(:, ["HGT", "UGRD", "VGRD"]), ...
    atmos = air_data(:, ["HGT", "TMP", "PRES"]), ...
    drag = aero_table);

flight_data.GeometricAltitude = interp1(air_data.PRES, air_data.HGT - launch_alt, ...
    Pa_per_mbar * flight_data.Pressure);


[basemap, rast] = readBasemapImage("sattelite", launch.lat + [-0.05 0.05], launch.lon + [-0.5 0.05]);
[landing.dx, landing.dy] = latlon2deltaxy(launch, landing);

figure(name = "Altitude history comparison");
hold on; grid on;


plot(flight_data.Time, flight_data.Altitude,  DisplayName = "Indicated");
% plot(flight_data.Time, flight_data.GeometricAltitude, ...
%     DisplayName = "Measured (corrected)")
plot(baseline_data.Time, baseline_data.Altitude,  DisplayName = "Baseline - geometric");
plot(atmos_data.Time, atmos_data.Altitude, DisplayName = "Custom atmos - geometric");
plot(wind_data.Time, wind_data.Altitude, DisplayName = "Custom wind - geometric");
plot(drag_data.Time, drag_data.Altitude, DisplayName = "Custom drag - geometric");
plot(all_data.Time, all_data.Altitude, DisplayName = "Custom all - geometric");
legend;

figure(name = "Landing location accuracy");
hold on; grid on;
plot(landing.dx, landing.dy, "xr", LineWidth = 2, DisplayName = "Landing");
% plot3(all_data.)
