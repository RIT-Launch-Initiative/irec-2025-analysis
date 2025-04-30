
figure; 
hold on

%% remove data 
% Find average of each column
col_means = mean(data_aoa, 1);

% Find indices of the two smallest column averages
[~, sortedIdx] = sort(col_means);
cols_to_remove = sortedIdx(1:2);

% Remove those columns from data_aoa
data_aoa(:, cols_to_remove) = [];

averageaoa=mean(data_aoa,2);
[~, mn] = min(mean(data_aoa,1));  [~, mx] = max(mean(data_aoa,1));      % get column indices
plot([averageaoa, data_aoa(:,mn), data_aoa(:,mx)]);



hold off
average_th = mean(data_settle_thresh);

xlabel('Time (ms)')
ylabel('Angle of attack (deg)')

xline(158,'-','BURNOUT');
xl = xline(0,'-','LAUNCHROD');
xl.LabelHorizontalAlignment = 'left';
yl=yline(average_th,'-',"AVG. 10% THRESHOLD");
yl.LabelVerticalAlignment ='top';
yl.LabelHorizontalAlignment = "center";
yr = yregion(-average_th,average_th,FaceColor="g",EdgeColor=[0.4 0 0.7]);
axis padded;
fontsize(24,'points');

legend('Average','MIN AOA','MAX AOA','Location','best');
average_settle = mean(data_settle_time)


