% This script will collect all of the data in various scripts for you and
% collect it
close all;clear; 




addpath(genpath("C:\\lmatlib"))
addpath(genpath("C:\lmatlib\sim"));

% open rocket integration intitialize 
otis_path = "C:\\irec-2025-analysis\\IREC_2025_M6000ST-0.ork";
otis = openrocket(otis_path);
sim = otis.sims("15MPH-TEXAS-36C-(TYP)"); %from openrocket
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end

% open rocket integration config
opts = sim.getOptions();

%Monte carlo variables
nSims = 2000; % change this to increase number of iterations. higher is better. minimum for any design review is 100 
wind_speed = 4.47; %m/s
wind_speed_spread =2.235; % m/s
wind_direction = 45;
temp_spread = 20; % c
temp = opts.getLaunchTemperature;
wind_direction_spread = 360;
time_step = 0.05;
turb = 0;

%conversion factors
m_sTOmph = 2.237136;
meterTofoot = 3.28084;
sTomS = 1/1000;

%initialize 
data_stabilityOffRod = zeros(1, nSims);
data_wind_speeds = zeros(1,nSims);
data_temp = zeros(1,nSims);
data_wind_direciton = zeros(1,nSims);
data_apogee = zeros(1,nSims);
data_time_to_stab = zeros(1,nSims);




for I = 1:nSims

    % set randomized sim variable
    opts.setLaunchIntoWind(false);
    wind_dir = wind_direction+(rand()-0.5)*wind_direction_spread;
    opts.setWindDirection(wind_dir);  
    opts.setWindTurbulenceIntensity(turb)
    opts.setWindSpeedAverage(wind_speed + (rand()-0.5)*wind_speed_spread);
    opts.setLaunchTemperature(temp + (rand()-0.5)*temp_spread);
    opts.setTimeStep(time_step)
        

    % run simulation
    data = openrocket.simulate(sim, outputs = "ALL");
    data_apogee(1,I) = max(data.Altitude);


    %limit data range
    data_range = timerange(eventfilter("LAUNCHROD"), eventfilter("BURNOUT"), "openleft");
    data = data(data_range, :);
            
    % collect interesting information
    stabilityMargin = data{:, 'Stability margin'};
    data_stabilityOffRod (1,I) = data{1, 'Stability margin'};

    % time to stability 1.5 data
    if data_stabilityOffRod(1,I) >= 1.5
        data_time_to_stab(1,I) = 0;
    else
        % Define the subarray starting at index 127
        marginSubarray = stabilityMargin(1:end);
        timeSubarray = seconds(data.Time(1:end));

        if any(marginSubarray >= 1.5)% Find the index range where stabilityMargin crosses 1.5
            % Use interp1 to find the exact time where stabilityMargin reaches 1.5
            data_time_to_stab(1,I) = (interp1(marginSubarray, timeSubarray, 1.5))-(timeSubarray(1,1));
        else
            data_time_to_stab(1,I) = NaN;  % No stability achieved
        end    
    end

    % save data
    data_wind_speeds(1,I) = data{1,"Wind velocity"};
    data_temp(1,I) = data{1,"Air temperature"};
    data_wind_direciton(1,I) = wind_dir;

    % randomize and display
    opts.randomizeSeed    
    disp(I)

end

%convert MKS to mph,C
data_apogee = data_apogee*meterTofoot;
data_temp = data_temp-273.15; % K to C

% %% Visualization 
% figure;
% tiledlayout(1,3)
% 
% % First tile: Wind Speeds vs. Stability Off Rod
% nexttile;
% title("Wind speed vs. Stability off the Rod")
% scatter(data_wind_speeds(1,:), data_stabilityOffRod(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
% xlabel("Wind Speeds(m/s)")
% ylabel("Stability Off Rod (cal)")
% plotlables(2);
% 
% 
% % Second tile: Wind Direction vs. Stability Off Rod
% nexttile;
% title("Wind direction vs. Stability off the Rod")
% scatter(data_wind_direciton(1,:), data_stabilityOffRod(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
% xlabel("Wind Direction (°)")
% ylabel("Stability Off Rod (cal)")
% plotlables(2);
% 
% % Third tile: Temperature vs. Stability Off Rod
% nexttile;
% 
% for J = 1:length(data_time_to_stab)
%     if data_stabilityOffRod(1,J) <= 1.5
%         scatter(data_time_to_stab(1,J)*1000, data_stabilityOffRod(1,J),36, 'filled', 'MarkerFaceColor', '#F76902')
%         ylabel("Stability Off Rod (cal)")
%         ylim([1 2])
%         ylabel('Stability(cal)'); %xlabel function
%         yline(1.5, 'b--', 'Minimum stability required by DTEG', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
%         xlabel('Time to 1.5 cal(ms)')
% 
%     end
% end
% grid ;
% grid minor;
% title("Time to 1.5 cal")
% 
% fontsize(16,"points")
% 
% 
% 
% 
% figure;
% 
% tiledlayout(1,3)
% 
% 
% nexttile;
% title("Wind speed vs. Apogee")
% scatter(data_wind_speeds(1,:), data_apogee(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
% xlabel("Wind Speeds(m/s)")
% ylabel("Apogee(ft)")
% ylim([8750 11250])
% ax = gca; % axes handle
% ax.YAxis.Exponent = 0;
% plotlables(1);
% 
% nexttile;
% title("Wind direction(°)vs. Apogee(ft)")
% scatter(data_wind_direciton(1,:), data_apogee(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
% xlabel("Wind Direction(°)")
% ylabel("Apogee(ft)")
% ylim([8750 11250])
% ax = gca; % axes handle
% ax.YAxis.Exponent = 0;
% plotlables(1);
% 
% nexttile;
% title("Temperature(°C) vs. Apogee(ft)")
% scatter(data_temp(1,:), data_apogee(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
% xlabel("Temperature(°C)")
% ylabel("Apogee(ft)")
% ylim([8750 11250])
% ax = gca; % axes handle
% ax.YAxis.Exponent = 0;
% plotlables(1);


fontsize(16,"points")

%% plot funciton
function plotlables(config)
    if config == 1
        
    elseif config == 2
        ylim([1 2])
            end
    grid;
    grid minor;
end

tiledlayout(2,1)
nexttile;
histogram(data_stabilityOffRod);
xlabel('Stability off the rod [cal]')
fontsize(16,"points")

xlabel('Stability (body calibers)'); %xlabel function
xline(1.5, 'k--', 'MIN STAB', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
fontsize(16,"points");

nexttile;
histogram(data_apogee);
xline(11000, 'k--', '+10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
xline(10000, 'k--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
xline(9000, 'k--', '-10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
xlim([8500 12500])
xlabel('Apogee [ft]')

fontsize(16,"points")
ax = gca; % axes handle
ax.XAxis.Exponent = 0;






