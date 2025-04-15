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
