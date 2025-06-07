%% Preface
%irec25 prelaunchday script
% goal: pull weather forecasts. estimate optimal nose mass
clear;


otis = openrocket("rocket_files\IREC_2025_M6000ST-0.ork");
sim = otis.sims("10MPH-TEXAS-36C-(TYP)");
site = launchsites("spaceport-midland");

disp("Available NCEP models:");
ncep.list

disp("Available GFS output grids: ");
ncep.list("gfs")

% Atmospheric model
times = datetime(2025, 06, 08, TimeZone = -hours(6)) + hours([10 12]);
launchtime = datetime(2024, 06, 08, 10, 21, 00, TimeZone = -hours(6));

%% Custom atmosphere & wind models
% Get air data table
airdata = atmosphere("gfs", "pgrb2.1p00", site.lat, site.lon, launchtime, ...
    minpres = 450, cache = "airdata.mat");  

% Celcius to Kelvin
airdata.TMP = airdata.TMP + 273.15;
