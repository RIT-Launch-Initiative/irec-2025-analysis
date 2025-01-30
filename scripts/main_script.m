% This script will collect all of the data in various scripts for you and
% collect it
clear; close all;

%% Global variables
addpath(genpath("C:\\lmatlib"))
simName = "MATLAB"; %from openrocket
otis_path = "C:\\irec-2025-analysis\\IREC_2025_M6000ST-0.ork";
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end
simName = "MATLAB";
nSims = 1000; % change this to increase number of iterations. higher is better. minimum for any design review is 100 
turbIntensity = 0.15; % fraction of 1
windSpeed = 15*0.447; %m/s converted to mph
temp = 36 +273.15;% kelvin converted to celcius

%conversion factors
m_sTOmph = 2.237136;
sTomS = 1/1000;


tiledlayout("vertical")

%%
% STABILITY OF THE ROD HISTOGRAM
% Purpose: This subscript will show you a histogram of the wind speed you put
% in. This will tell you the most likely stability off the rod at speed
% with a confidence interval. Use this to ensure go/no go wind speed is stable.

% [stabOffRod,windOffRod] = stabLoop (simName,nSims,turbIntensity,windSpeed,otis_path,temp);
% nexttile 
% hist(stabOffRod,(nSims/10));
% h = findobj(gca,'Type','patch');
% h.FaceColor = ['#F76902'];
% h.EdgeColor = 'w';
% axis padded;
% xlabel('Stability (body calibers)'); % Corrected: use xlabel function
% xline(1.5, 'b--', 'Minimum stability required by DTEG', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
% title('Standard Distribution of Stability Off the Rod'); % Corrected: use title function
% 
%     %confidence interval for stability. this will give you a 95% CI for
%     %your stab off the rod
%     x = mean(stabOffRod);
%     z = 1.96;
%     s = std(stabOffRod);    
%     ci_high = x + z*(s/(sqrt(nSims)));
%     ci_low  = x - z*(s/(sqrt(nSims)));
% 
%     formatSpec = 'There is 0.95 probability that the stability off the rod at %4.1fm/s wind speed, will be between %4.2f cal and %4.2f cal\n';
%     fprintf(formatSpec,windSpeed,ci_low,ci_high)


% %%
% %temperatue vs apogee 
% %configure
% windSpeeds =(0:0.5:10);
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

%% apogee vs. launch angle
%configure
high_angle = 86;
low_angle = 82;
angleStep = 0.1;

%run the sub script
[launchAngles,maxAltitudes] = angleApogee (angleStep,high_angle,low_angle,simName,turbIntensity,windSpeed,otis_path);

% visulization 
nexttile

% Visualization
plot((rad2deg(launchAngles)), maxAltitudes, 'o-', 'MarkerFaceColor', 'b', 'LineWidth', 2);
xlabel('Launch Angle (°) from vertical');
ylabel('Maximum Altitude (ft)');
title(sprintf('Maximum Altitude vs Launch Angle (Wind Speed = 15 mph)'));
grid on;
box on;
axis padded;
ylim([8750 11250])
yline(11000, 'r--', '+10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
yline(10000, 'g--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
yline(9000, 'r--', '-10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
fontsize(16,"points");

%Remove scientific notation from y-axis
ax = gca;
ax.YAxis.Exponent = 0;
ytickformat('%.0f');  % Format y-ticks as whole numbers

%% apogee vs. temperature
%configure
temperatures = 10:1:50;

[maxAltitudes] = apogeeTemp(temperatures,simName,turbIntensity,windSpeed,otis_path);

maxAltitudes = maxAltitudes*3.28084;

% Visualization
nexttile
plot(temperatures, maxAltitudes, 'o-', 'MarkerFaceColor', 'b', 'LineWidth', 2);
xlabel('Temperature (°C)');
ylabel('Maximum Altitude (ft)');
axis padded;
title(sprintf('Maximum Altitude vs Launch Temperature (Wind Speed = 15 mph)'));
grid on;
box on;
hold on;
ylim([8750 11250])
yline(11000, 'r--', '+10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
yline(10000, 'g--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
yline(9000, 'r--', '-10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');

fontsize(16,"points")

% Remove scientific notation from y-axis
ax = gca;
ax.YAxis.Exponent = 0;
ytickformat('%.0f');  % Format y-ticks as whole numbers

hold off;