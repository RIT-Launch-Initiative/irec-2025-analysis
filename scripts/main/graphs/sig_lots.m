close all;
% figure;
% scatter(data_wind_speeds,data_apogee)

figure;
scatter(data_wind_speeds,data_stabOffRod)
stability_range = max(data_stabOffRod) - min(data_stabOffRod)

figure;
scatter(data_temp_init,data_apogee)

figure;
scatter(data_wind_dirs,data_stabOffRod)