% This script will collect all of the data in various scripts for you and
% collect it
clear; close all;

%% Global variables
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
nSims = 15; % change this to increase number of iterations. higher is better. minimum for any design review is 100 
turb_spread = 0.05;
wind_speed = 6.7; %m/s
wind_speed_spread = 5; % m/s
wind_direction = 45;
temp_spread = 20; % c
temp = opts.getLaunchTemperature;
wind_angle_spread = 45;

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
    wind_dir = wind_direction+(rand()-0.5)*wind_angle_spread;
    opts.setWindDirection(wind_dir);    
    opts.setWindSpeedAverage(wind_speed + (rand()-0.5)*wind_speed_spread);
    opts.setLaunchTemperature(temp + (rand()-0.5)*temp_spread);

    % run simulation
    data = openrocket.simulate(sim, outputs = "ALL");

    data_apogee(1,I) = max(data.Altitude);


    %limit data range
    data_range = timerange(eventfilter("LAUNCHROD"), eventfilter("BURNOUT"), "openleft");
    data = data(data_range, :);
            
    % collect interesting information
    stabilityMargin = data{:, 'Stability margin'};
    data_stabilityOffRod (1,I) = data{1, 'Stability margin'};

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



    data_wind_speeds(1,I) = data{1,"Wind velocity"};
    data_temp(1,I) = data{1,"Air temperature"};
    data_wind_direciton(1,I) = wind_dir;

    opts.randomizeSeed    
    disp(I)

end

%convert MKS to mph,C
data_apogee = data_apogee*meterTofoot;
data_temp = data_temp-273.15; % K to C

figure;
tiledlayout(1,3)

% First tile: Wind Speeds vs. Stability Off Rod
nexttile;
scatter(data_wind_speeds(1,:), data_stabilityOffRod(1,:), "filled")
xlabel("Wind Speeds")
ylabel("Stability Off Rod")
plotlables(2);


% Second tile: Wind Direction vs. Stability Off Rod
nexttile;
scatter(data_wind_direciton(1,:), data_stabilityOffRod(1,:), "filled")
xlabel("Wind Direction")
ylabel("Stability Off Rod")
plotlables(2);

% Third tile: Temperature vs. Stability Off Rod
nexttile;
for J = J:height(data_time_to_stab)
    if data_stabilityOffRod(1,J) <= 1.5
        scatter(data_stabilityOffRod(1,:), data_time_to_stab(1,:), "filled")
        xlabel("Stability Off Rod")
        ylabel("Time to 1.5 cal")
        xlim([1 2])
        xlabel('Stability (body calibers)'); %xlabel function
        xline(1.5, 'b--', 'Minimum stability required by DTEG', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
    end
end




figure;

tiledlayout(1,3)


nexttile;
scatter(data_wind_speeds(1,:), data_apogee(1,:), "filled")
xlabel("Wind Speeds")
ylabel("Apogee")
ylim([8750 11250])
ax = gca; % axes handle
ax.YAxis.Exponent = 0;
plotlables(1);

nexttile;
scatter(data_wind_direciton(1,:), data_apogee(1,:), "filled")
xlabel("Wind Direction")
ylabel("Apogee")
ylim([8750 11250])
ax = gca; % axes handle
ax.YAxis.Exponent = 0;
plotlables(1);

nexttile;
scatter(data_temp(1,:), data_apogee(1,:), "filled")
xlabel("Temperature")
ylabel("Apogee")
ylim([8750 11250])
ax = gca; % axes handle
ax.YAxis.Exponent = 0;
plotlables(1);

function plotlables(config)
    if config == 1
        yline(11000, 'r--', '+10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
        yline(10000, 'g--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
        yline(9000, 'r--', '-10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
        fontsize(16,"points");
    elseif config == 2
        ylim([1 2])
        ylabel('Stability (body calibers)'); %xlabel function
        yline(1.5, 'b--', 'Minimum stability required by DTEG', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');

    end

end










% STABILITY OF THE ROD HISTOGRAM
% Purpose: This subscript will show you a histogram of the wind speed you put
% in. This will tell you the most likely stability off the rod at speed
% with a confidence interval. Use this to ensure go/no go wind speed is stable.

% [stabOffRod,windOffRod] = stabLoop (simName,nSims,turbIntensity,windSpeed,otis_path,default_temp);
% nexttile 
% hist(stabOffRod,(nSims/10));
% h = findobj(gca,'Type','patch');
% h.FaceColor = ['#F76902'];
% h.EdgeColor = 'w';
% axis padded;
% ylabel('# of events');% ylabl function
% xlabel('Stability (body calibers)'); %xlabel function
% xline(1.5, 'b--', 'Minimum stability required by DTEG', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
% 
% title('Standard Distribution of Stability Off the Rod at 15mph'); % Corrected: use title function

%confidence interval for stability. this will give you a 95% CI for
%your stab off the rod
% x = mean(stabOffRod);
% z = 1.96;
% s = std(stabOffRod);    
% ci_high = x + z*(s/(sqrt(nSims)));
% ci_low  = x - z*(s/(sqrt(nSims)));

% 
% % %% wip 
% % %stability vs. wind direction
% % %configure
% % 
% % windDirections = (1);
% % 
% % [stabOffRod,windOffRod] = stabWindDireciton(simName,nSims,turbIntensity,windSpeed,otis_path,temp);
% % nexttile 
% % hist(stabOffRod,(nSims/10));
% % h = findobj(gca,'Type','patch');
% % h.FaceColor = ['#F76902'];
% % h.EdgeColor = 'w';
% % axis padded;
% % xlabel('Stability (body calibers)'); % Corrected: use xlabel function
% % xline(1.5, 'b--', 'Minimum stability required by DTEG', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
% % title('Standard Distribution of Stability Off the Rod'); % Corrected: use title function
% % 
% %     %confidence interval for stability. this will give you a 95% CI for
% %     %your stab off the rod
% %     x = mean(stabOffRod);
% %     z = 1.96;
% %     s = std(stabOffRod);    
% %     ci_high = x + z*(s/(sqrt(nSims)));
% %     ci_low  = x - z*(s/(sqrt(nSims)));
% % 
% %     formatSpec = 'There is 0.95 probability that the stability off the rod at %4.1fm/s wind speed, will be between %4.2f cal and %4.2f cal\n';
% %     fprintf(formatSpec,windSpeed,ci_low,ci_high)
% 
% 
% %%
% %time to 1.5 cal
% %configure
% windSpeeds =(0:1:11.5);
% 
% %run the sub script
% [stabWindData,timeStabWindData] = stabWindTemp (windSpeeds,otis_path,simName);
% windSpeeds = windSpeeds';
% % visulization 
% nexttile
% 
% for I = 1:(height(windSpeeds))
%     scatter(m_sTOmph*(windSpeeds(I,1)),(stabWindData(I,1)),'filled','MarkerFaceColor','#F76902')
%     hold on;
% end
% 
% x_fit = m_sTOmph*windSpeeds;
% y_fit_data = stabWindData;
% 
% % Calculate quadratic fit coefficients
% p = polyfit(x_fit, y_fit_data, 2);
% x_fit_curve = linspace(min(x_fit), max(x_fit), 100);
% y_fit_curve = polyval(p, x_fit_curve);
% 
% % Plot the quadratic fit
% plot(x_fit_curve, y_fit_curve, 'k--', 'LineWidth', 2, ...
%     'DisplayName', sprintf('Quadratic Fit'));
% 
% xline(20, 'b--', 'Go/No-Go', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');   
% yline(1.5, 'b--', 'Minimum off the rod stability', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','left');
% xlabel('Wind Speed (mph)');
% ylabel('Apogee Altitude (m)');
% title('Apogee vs. Wind Speed at Different Temperatures');
% grid on;
% grid minor;
% axis padded;
% hold off;
% fontsize(16,"points")
% 
% nexttile
% for I = 1:(height(timeStabWindData))
%     scatter(m_sTOmph*(windSpeeds(I,1)),(sTomS*timeStabWindData(I,1)),'filled','MarkerFaceColor','#F76902')
%     hold on;
% end
% 
% xlabel('Wind Speed (mph)');
% ylabel('Time(ms)');
% title('Time to achive 1.5 cal stability');
% fontsize(16,"points")
% grid on;
% grid minor;
% axis padded;
% 



% %% apogee vs. launch angle
% %configure
% high_angle = 86;
% low_angle = 82;
% angleStep = 0.1;
% 
% %run the sub script
% [launchAngles,maxAltitudes] = angleApogee (angleStep,high_angle,low_angle,simName,turbIntensity,windSpeed,otis_path);
% 
% launchAngles = (low_angle:angleStep:high_angle);
% 
% % visulization 
% nexttile
% 
% % Visualization
% plot(((launchAngles)), maxAltitudes, 'o-', 'MarkerFaceColor', 'b', 'LineWidth', 2);
% xlabel('Launch Angle (°) from vertical');
% ylabel('Maximum Altitude (ft)');
% title(sprintf('Maximum Altitude vs Launch Angle (Wind Speed = 15 mph)'));
% grid on;
% box on;
% axis padded;
% ylim([8750 11250])
% yline(11000, 'r--', '+10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
% yline(10000, 'g--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
% yline(9000, 'r--', '-10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
% fontsize(16,"points");
% 
% %Remove scientific notation from y-axis
% ax = gca;
% ax.YAxis.Exponent = 0;
% ytickformat('%.0f');  % Format y-ticks as whole numbers
% 
% %% apogee vs. temperature
% %configure
% temperatures = 27:1:46;
% 
% [maxAltitudes] = apogeeTemp(temperatures,simName,turbIntensity,windSpeed,otis_path);
% 
% maxAltitudes = maxAltitudes*3.28084;
% 
% % Visualization
% nexttile
% plot(temperatures, maxAltitudes, 'o-', 'MarkerFaceColor', 'b', 'LineWidth', 2);
% xlabel('Temperature (°C)');
% ylabel('Maximum Altitude (ft)');
% axis padded;
% title(sprintf('Maximum Altitude vs Launch Temperature (Wind Speed = 15 mph)'));
% grid on;
% box on;
% hold on;
% ylim([8750 11250])
% yline(11000, 'r--', '+10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
% yline(10000, 'g--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
% yline(9000, 'r--', '-10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
% 
% fontsize(16,"points")
% 
% % Remove scientific notation from y-axis
% ax = gca;
% ax.YAxis.Exponent = 0;
% ytickformat('%.0f');  % Format y-ticks as whole numbers
% 
% % hold off;