close all;

%ok so this may look bad like I am deleting data. well that is what I am
%doing.. I believe the issues is caused by how I am cleaning the data in
%the main script. not going to investigate further... 
k = 2;
colMeans = mean(data_aoa,1);      
[~, idx] = mink(colMeans, k);
data_aoa(:, idx) = [];



averageaoa=mean(data_aoa,2);
[~, mn] = min(mean(data_aoa,1));  [~, mx] = max(mean(data_aoa,1));      % get column indices
plot([averageaoa, data_aoa(:,mn), data_aoa(:,mx)]);

hold off
average_th = mean(data_settle_threshold);

xlabel('Time (ms)')
ylabel('Angle of attack (deg)')

xline(158,'-','BURNOUT');
xl = xline(0,'-','LAUNCHROD');
xl.LabelHorizontalAlignment = 'left';
yl=yline(average_th,'-',"AVG. 10% THRESHOLD");
yl.LabelVerticalAlignment ='top';
yl.LabelHorizontalAlignment = "center";
yr = yregion(-average_th,average_th,FaceColor="g",EdgeColor=[0.4 0 0.7]);
fontsize(16,'points');

legend('Average','MIN AOA','MAX AOA','Location','best');
average_settle = mean(data_settle_time)

average_overshoot = mean(data_overshoot)