figure

plot(or_data.Time,(or_data.('Vertical velocity')*3.28084))
hold on

plot(data_rc2.Time,data_rc2.Velocity)


plot(data_rc1.Time,data_rc1.Velocity)

plot(time, velocity_grad);

hold off

xlim([seconds(0.02) seconds(10)])

legend('Openrocket','RRC3-1','RRC3-2','Payload data')
grid minor

