% This script will collect all of the data in various scripts for you and
% collect it
clear; close all;

%configure this script
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

tiledlayout("vertical")

%%
% % STABILITY OF THE ROD HISTOGRAM
% % Purpose: This subscript will show you a histogram of the wind speed you put
% % in. This will tell you the most likely stability off the rod at speed
% % with a confidence interval. Use this to ensure go/no go wind speed is stable.
% sub1 = true; % CHANGE THIS VALUE TO RUN SUBSCRIPT #1
% if sub1 == 1
%     [stabOffRod,windOffRod] = stabLoop (simName,nSims,turbIntensity,windSpeed,otis_path,temp);
%     nexttile 
%     hist(stabOffRod,(nSims/10));
%     h = findobj(gca,'Type','patch');
%     h.FaceColor = ['#F76902'];
%     h.EdgeColor = 'w';
%     axis padded;
%     xlabel('Stability (body calibers)'); % Corrected: use xlabel function
%     xline(1.5, 'b--', 'Minimum stability required by DTEG', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
%     title('Standard Distribution of Stability Off the Rod'); % Corrected: use title function
% 
%         %confidence interval for stability. this will give you a 95% CI for
%         %your stab off the rod
%         x = mean(stabOffRod);
%         z = 1.96;
%         s = std(stabOffRod);    
%         ci_high = x + z*(s/(sqrt(nSims)));
%         ci_low  = x - z*(s/(sqrt(nSims)));
% 
%         formatSpec = 'There is 0.95 probability that the stability off the rod at %4.1fm/s wind speed, will be between %4.2f cal and %4.2f cal\n';
%         fprintf(formatSpec,windSpeed,ci_low,ci_high)
% end

%%
%temperatue vs apogee
subscript2 = true;% change to true to run the sub script #2 
if subscript2 == 1    
    %configure
    windSpeeds =(0:0.5:10);
    
    %run the sub script
    [stabWindData,timeStabWindData] = stabWindTemp (windSpeeds,otis_path,simName);
    windSpeeds = windSpeeds';
    % visulization 
    nexttile
    
    for I = 1:(height(windSpeeds))
        scatter(m_sTOmph*(windSpeeds(I,1)),(stabWindData(I,1)),'filled','MarkerFaceColor','#F76902')
        hold on;
    end
    
    x_fit = m_sTOmph*windSpeeds;
    y_fit_data = stabWindData;

    % Calculate quadratic fit coefficients
    p = polyfit(x_fit, y_fit_data, 2);
    x_fit_curve = linspace(min(x_fit), max(x_fit), 100);
    y_fit_curve = polyval(p, x_fit_curve);
    
    % Plot the quadratic fit
    plot(x_fit_curve, y_fit_curve, 'k--', 'LineWidth', 2, ...
        'DisplayName', sprintf('Quadratic Fit'));
    
    xline(20, 'b--', 'Go/No-Go', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');   
    yline(1.5, 'b--', 'Minimum off the rod stability', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','left');
    xlabel('Wind Speed (mph)');
    ylabel('Apogee Altitude (m)');
    title('Apogee vs. Wind Speed at Different Temperatures');
    grid on;
    grid minor;
    axis padded;
    hold off;
    fontsize(16,"points")

    nexttile
    for I = 1:(height(timeStabWindData))
        scatter(m_sTOmph*(windSpeeds(I,1)),(timeStabWindData(I,1)),'filled','MarkerFaceColor','#F76902')
        hold on;
    end

    xlabel('Wind Speed (mph)');
    ylabel('Time(s)');
    title('Time to achive 1.5 cal stability');
    fontsize(16,"points")
    grid on;
    grid minor;
    axis padded;



    
end
%%




%launch angles to test

%wind speed to test

