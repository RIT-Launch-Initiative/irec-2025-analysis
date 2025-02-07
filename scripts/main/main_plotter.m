close all;
%% Visualization 
figure;
tiledlayout(1,3)

% First tile: Wind Speeds vs. Stability Off Rod
nexttile;
title("Wind speed vs. Stability off the Rod")
scatter(data_wind_speeds(1,:), data_stabilityOffRod(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
xlabel("Wind Speeds(m/s)")
ylabel("Stability Off Rod (cal)")
plotlables(2);


% Second tile: Wind Direction vs. Stability Off Rod
nexttile;
title("Wind direction vs. Stability off the Rod")
scatter(data_wind_direciton(1,:), data_stabilityOffRod(1,:), 36, 'filled', 'MarkerFaceColor', '#F76902')
xlabel("Wind Direction (°)")
ylabel("Stability Off Rod (cal)")
plotlables(2);

% Third tile: Temperature vs. Stability Off Rod
nexttile;

for J = 1:length(data_time_to_stab)
    if data_stabilityOffRod(1,J) <= 1.5
        scatter(data_time_to_stab(1,J)*1000, data_stabilityOffRod(1,J),36, 'filled', 'MarkerFaceColor', '#F76902')
        ylabel("Stability Off Rod (cal)")
        ylim([1 2])
        ylabel('Stability(cal)'); %xlabel function
        yline(1.5, 'b--', 'Minimum stability required by DTEG', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
        xlabel('Time to 1.5 cal(ms)')

    end
end
grid ;
grid minor;
title("Time to 1.5 cal")

fontsize(16,"points")


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



%% plot funciton
function plotlables(config)
    if config == 1
        yline(11000, 'b--', '+10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
        yline(10000, 'k--', 'Target Apogee', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
        yline(9000, 'b--', '-10%', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
        fontsize(16,"points");
    elseif config == 2
        ylim([1 2])
        ylabel('Stability (calibers)'); %xlabel function
        yline(1.5, 'b--', 'Minimum stability required by DTEG', 'LabelVerticalAlignment','middle', 'LabelHorizontalAlignment','center');
    end
    grid;
end