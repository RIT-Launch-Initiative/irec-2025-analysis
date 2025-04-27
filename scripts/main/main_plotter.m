close all;
%% Visualization 
% settle time vs wind speed.
figure;
scatter(data_wind_speeds,data_overshoot)
xlabel('Wind speed [m/s]')
ylabel('Overshoot')

figure;
tiledlayout(2,1)
nexttile;
histogram(data_stabilityOffRod);
xlabel('Stability off the rod [cal]')
xline(1.5, 'k--', 'MIN STABILITY', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','right');
fontsize(16,"points")
axis padded

nexttile;
histogram(data_apogee);
xlabel('Apogee [ft]')
xline(11000, 'k--', '+10%', 'LabelVerticalAlignment','top', 'LabelHorizontalAlignment','right');
xline(10000, 'k--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','right');
xline(9000, 'k--', '-10%', 'LabelVerticalAlignment','top', 'LabelHorizontalAlignment','right');
fontsize(16,"points")
axis padded

xlim([8750 11250])
ax = gca; % axes handle
ax.XAxis.Exponent = 0;



figure;
tiledlayout(1,3)
nexttile;

scatter(data_wind_speeds(1,:), data_stabilityOffRod(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
xlabel("Wind Speeds [m/s]")
xlim([0 10])
ylabel("Stability Off Rod [cal]")
plotlables(2);
xline(6.7, 'b--', 'SIMULATION NOMINAL (15MPH)', 'LabelVerticalAlignment','top', 'LabelHorizontalAlignment','right');
xline(8.94, 'b--', 'GO NO-GO WIND SPEED (20MPH)', 'LabelVerticalAlignment','top', 'LabelHorizontalAlignment','right');
title("Wind speed vs. Stability off the Rod")

nexttile;

scatter(data_wind_speeds(1,:), data_time_to_stab(1,:)*1000, 36, 'filled', 'MarkerFaceColor', '#F76902')
xlabel("Wind Speeds [m/s]")
xline(8.94, 'b--', 'GO NO-GO WIND SPEED', 'LabelVerticalAlignment','top', 'LabelHorizontalAlignment','right');
ylabel("Time to 1.5 cal [ms]")
grid;
title("Wind speed vs. Time to 1.5 cal")


nexttile;
avg_time = [];
for J = 1:length(data_time_to_stab)
    if data_stabilityOffRod(1,J) <= 1.5
        scatter(data_stabilityOffRod(1,J), data_time_to_stab(1,J)*1000,36, 'filled', 'MarkerFaceColor', '#F76902')
        avg_time = [avg_time, data_time_to_stab(1, J)];
        hold on;
   end
end
hold off;
xlabel("Stability Off Rod [cal]")
xlim([1 1.6])
xline(1.5, 'b--', 'MIN ALLOWED STABILITY', 'LabelVerticalAlignment','top', 'LabelHorizontalAlignment','right');
ylabel('Time to 1.5 cal [ms]')
grid;
title("Time to 1.5 cal")
fontsize(16,"points")

avg_time = mean(avg_time)


figure;
tiledlayout(1,3)
nexttile;
title("Wind speed vs. Apogee")
scatter(data_wind_speeds(1,:), data_apogee(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
xlabel("Wind Speeds (m/s)")
ylabel("Apogee(ft)")
ylim([8750 11250])
ax = gca; % axes handle
ax.YAxis.Exponent = 0;
plotlables(1);

nexttile;
title("Wind direction (°)vs. Apogee(ft)")
scatter(data_wind_direciton(1,:), data_apogee(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
xlabel("Wind Direction (°)")
ylabel("Apogee (ft)")
ylim([8750 11250])
ax = gca; % axes handle
ax.YAxis.Exponent = 0;
plotlables(1);

nexttile;
title("Temperature (°C) vs. Apogee(ft)")
scatter(data_temp(1,:), data_apogee(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
xlabel("Temperature(°C)")
ylabel("Apogee(ft)")
ylim([8750 11250])
ax = gca; % axes handle
ax.YAxis.Exponent = 0;
plotlables(1);

figure;

title("Temperature [°C] vs. Apogee [ft]")
scatter(data_temp(1,:), data_apogee(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
xlabel("Temperature [°C]")
ylabel("Apogee [ft]")
ylim([8750 11250])
ax = gca; % axes handle
ax.YAxis.Exponent = 0;
plotlables(1);

figure;
plot_openrocket(data, "Stability margin", "Angle of attack", ...
    start_ev = "LAUNCHROD", end_ev = "APOGEE", labels = ["LAUNCHROD", "BURNOUT"]);
fontsize(16,"points")

%% plot funciton
function plotlables(config)
    if config == 1
        yline(11000, 'b--', '+10%', 'LabelVerticalAlignment','bottom', 'LabelHorizontalAlignment','right');
        yline(10000, 'k--', 'Target Apogee', 'LabelVerticalAlignment','bottom', 'LabelHorizontalAlignment','right');
        yline(9000, 'b--', '-10%', 'LabelVerticalAlignment','bottom', 'LabelHorizontalAlignment','right');
        fontsize(16,"points");
    elseif config == 2
        ylim([1 2])
        ylabel('Stability [cal]'); %xlabel function
        yline(1.5, 'b--', 'MIN ALLOWED STABILITY', 'LabelVerticalAlignment','BOTTOM', 'LabelHorizontalAlignment','LEFT');
    end
    grid;
end


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

