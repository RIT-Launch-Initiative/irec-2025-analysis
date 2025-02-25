% MATLAB Script to plot Angle of Attack vs Time from two timetables
% Assumes you have two timetables: timetable1 and timetable2

% Sample data for demonstration purposes
% Replace these timetables with your actual data
% timetable1 = timetable(seconds(0:10)', rand(11, 1) * 10, 'VariableNames', {'AngleOfAttack'});
% timetable2 = timetable(seconds(0:20)', rand(21, 1) * 8, 'VariableNames', {'AngleOfAttack'});

% Load your timetables here (for example, from a file)
% Example: timetable1 = readtable('file1.csv'); timetable2 = readtable('file2.csv');

% Plotting the timetables
figure;

% Plot first timetable
plot(omen_aoa.Time, omen_aoa.Angle of attack, '-o', 'DisplayName', 'Timetable 1', 'LineWidth', 1.5);
hold on;

% Plot second timetable
plot(otis_aoa.Time, otis_aoa.Angle of attack, '-x', 'DisplayName', 'Timetable 2', 'LineWidth', 1.5);

% Axis labels and title
xlabel('Time');
ylabel('Angle of Attack (deg)');
title('Angle of Attack vs Time');

% Add legend
legend;

grid on;
hold off;