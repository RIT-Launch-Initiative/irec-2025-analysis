figure;
scatter(data_wind_speeds,data_settle_time)

figure; 
hold on
for i = 1:numel(data_aoa)
    plot(data_aoa{i})    
end
hold off
average_th = mean(data_settle_threshold);

xlabel('Time ms')
ylabel('Angle of attack (deg)')
xline(158,'-','BURNOUT');
xline(0,'-','LAUNCHROD');
yr = yregion(-average_th,average_th,FaceColor="g",EdgeColor=[0.4 0 0.7]);
title('AOA over time')

average_settle = mean(data_settle_time)
