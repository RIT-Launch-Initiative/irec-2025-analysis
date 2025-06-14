clear;
close all

% openrocket
rocket_file = "rocket_files\IREC_2025_M6000ST-0.ork";
sim_name    = "10MPH-TEXAS-36C-(TYP)";
site_name   = "spaceport-midland";
nose_cmp_name = 'Adjustable stability weight(s)';
otis = openrocket(rocket_file);
sim  = otis.sims("10MPH-TEXAS-36C-(TYP)");
opts = sim.getOptions();

site = launchsites("spaceport-midland")

nominal_launch_time = datetime(2025,06,11,13,0,0,'TimeZone','-05:00');

airdata = atmosphere("hrrr","wrfprsf",site.lat,site.lon,nominal_launch_time, ...
                             minpres=450);

airdata.TMP = airdata.TMP + 273.15;

or_data      = otis.simulate(sim,'outputs','ALL', ...
             atmos=airdata(:,["HGT","PRES","TMP","UGRD","VGRD"]));






filename1 = 'post_flight_data\_T144RITrk__06-11-2025_13_32_22.csv';
filename2 = 'post_flight_data\OTIS Primary RRC3.csv'
filename3 = 'post_flight_data\OTIS Secondary RRC3.csv'

opts = detectImportOptions(filename1, 'Delimiter', ',', 'PreserveVariableNames', true);
data_payload = readtable(filename1, opts);
data_rc1 = readtable(filename2,opts);
data_rc2 = readtable(filename3,opts);

mtf = 3.28084;

site = launchsites("spaceport-midland");

% Convert UTCTIME to datetime format
data_payload.UTCTIME = datetime(data_payload.UTCTIME, 'InputFormat', 'MMM dd yyyy HH:mm:ss.SSS z', 'TimeZone', 'UTC');
data_rc1.Time = str2double(data_rc1.Time);
data_rc2.Time = str2double(data_rc2.Time);


% Read Altitude and Time from the data structure
altitude = data_rc1.Altitude;  % Assuming Altitude is in meters
time = data_rc1.Time;          % Assuming Time is in seconds or datetime

% Convert datetime to seconds if needed
if isdatetime(time)
    time = seconds(time - time(1));
end

% Velocity using diff (finite difference)
velocity_diff = diff(altitude) ./ diff(time);
velocity_time_diff = time(1:end-1) + diff(time)/2;  % Midpoints

% Velocity using gradient (smoother and better for uneven spacing)
velocity_grad = gradient(altitude) ./ gradient(time);

% Plot both for comparison
figure;
hold on;
plot(velocity_time_diff, velocity_diff, 'b-', 'DisplayName', 'diff');
plot(time, velocity_grad, 'r--', 'DisplayName', 'gradient');
xlim([0 15])
xlabel('Time (s)');
ylabel('Velocity (m/s)');
title('Vertical Velocity Comparison');
legend('Location','best');
grid on;
hold off;



% max speed
max_rc1 = max(data_rc1.Velocity)
max_rc2 = max(data_rc2.Velocity)



% Plot altitude vs time


data_payload.ALT = data_payload.ALT-site.alt*mtf;


figure;
tlo = tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
nexttile(tlo,1)

plot(data_payload.UTCTIME, data_payload.ALT);
ylim([0 9500])
title('Payload Data');

nexttile(tlo,2)
plot(data_rc1.Time,data_rc1.Altitude);
ylim([0 9500])
title('RRC3_1 Data');

nexttile(tlo,3)
plot(data_rc2.Time,data_rc2.Altitude);
ylim([0 9500])
% xlim([0 2])
% xline(1.6,'-','MOTOR BURNOUT')
% xline(0.24,'-','OFF ROD')
% yline(814,'-',"OR ALT @ BURNOUT",'LabelHorizontalAlignment','left')
% y

title('RRC3_2 Data');


figure

plot(or_data.Time,(or_data.('Vertical velocity')*3.28084))
hold on

plot(data_rc2.Time,data_rc2.Velocity)


plot(data_rc1.Time,data_rc1.Velocity)
hold off

xlim([seconds(0.02) seconds(5)])




