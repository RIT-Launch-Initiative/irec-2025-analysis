close all;
% figure;
% scatter(data_wind_speeds,data_overshoot)
% title('wind speed vs overshoot')
% axis padded;
% 
% 
% figure;
% scatter(data_temp,data_overshoot)
% title(' temp vs overshoot')
% 
% figure;
% scatter(data_wind_direciton,data_overshoot)
% title('wind direction vs overshoot')

figure; 
hold on

averageaoa=mean(data_aoa,2);


plot(averageaoa);

hold off
average_th = mean(data_settle_threshold);

xlabel('Time (ms)')
ylabel('Angle of attack (deg)')
xline(158,'-','BURNOUT');
xl = xline(0,'-','LAUNCHROD');
xl.LabelHorizontalAlignment = 'left';
yr = yregion(-average_th,average_th,FaceColor="g",EdgeColor=[0.4 0 0.7]);
axis padded;
title('AOA through monte carlo')
fontsize(16,'points');

average_settle = mean(data_settle_time)
