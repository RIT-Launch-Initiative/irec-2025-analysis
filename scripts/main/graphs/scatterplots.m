close all;
% figure;
% scatter(data_wind_speeds,data_apogee)

figure;
scatter(data_wind_speeds * 2.237136, data_stabOffRod, ...
    16, ...            % marker size
    'b', ...           % 'b' for blue
    'filled' ...       % filled circles
);




xlabel('Wind speed [mph]')
ylabel('Stability off the rod [cal]')
set(gca,'FontSize',16)
axis padded
grid minor

% figure;
% scatter(data_temp_init,data_apogee)
% 
% figure;
% scatter(data_wind_dirs,data_stabOffRod)