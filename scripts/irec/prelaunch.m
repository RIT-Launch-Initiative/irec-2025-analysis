%% Preface
%irec25 prelaunchday script
% goal: pull weather forecasts. estimate optimal nose mass
clear;

% conversions
m2f=3.28084;

otis = openrocket("rocket_files\IREC_2025_M6000ST-0.ork");
sim = otis.sims("10MPH-TEXAS-36C-(TYP)");
site = launchsites("spaceport-midland");

baseline_flight_data = otis.simulate(sim, outputs = "ALL");

% Atmospheric model
launchtime = datetime(2024, 06, rand, 10, 00, 00, TimeZone = -hours(6));

%% Custom atmosphere & wind models
% Get air data table
airdata = atmosphere("gfs", "pgrb2.1p00", site.lat, site.lon, launchtime, ...
    minpres = 450, cache = "airdata.mat");  

% Celcius to Kelvin
airdata.TMP = airdata.TMP + 273.15;

data = otis.simulate(sim, outputs = "ALL", ...
    wind = airdata(:, ["HGT", "UGRD", "VGRD", "PRES", "TMP"]));

apogee = max(data.Altitude) * m2f

fprintf("Maximum altituide %0.0f feet\n",apogee)

figure;

plot_openrocket(data, "Altitude", "Total velocity", ...
    end_ev = "GROUND_HIT", labels = ["BURNOUT", "APOGEE", "MAIN"]);

figure
plot_openrocket(data, "Stability margin", "Angle of attack", ...
    start_ev = "LAUNCHROD", end_ev = "APOGEE", labels = ["LAUNCHROD", "BURNOUT"]);
