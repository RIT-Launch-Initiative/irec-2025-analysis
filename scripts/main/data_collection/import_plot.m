% MATLAB script: compare average AOA distributions between OMEN and OTIS_DATA

% --- User configuration ---
mypth = 'C:/irec-2025-analysis/tech_report_figs';  % folder containing the CSV/Excel files

% Filenames (adjust extensions if needed)
omenFile = 'OMEN_DATA.xlsx';
otisFile = 'OTIS_DATA.xlsx';
sheetName = 'AOA';  % sheet with AOA data

% Build full paths
omenPath = fullfile(mypth, omenFile);
otisPath = fullfile(mypth, otisFile);

% Read tables (fallback to default sheet if 'AOA' not found)
try
    T_omen = readtable(omenPath, 'Sheet', sheetName);
catch
    T_omen = readtable(omenPath);
end
try
    T_otis = readtable(otisPath, 'Sheet', sheetName);
catch
    T_otis = readtable(otisPath);
end

% Convert to numeric arrays
data_omen = table2array(T_omen);
data_otis = table2array(T_otis);

% Compute average AOA for each row across simulations
avg_omen = mean(data_omen, 2);
avg_otis = mean(data_otis, 2);

% Plot both on one figure for direct comparison
figure;
plot(avg_omen, '-o', 'LineWidth', 1.5, 'DisplayName', 'OMEN'); hold on;
plot(avg_otis, '-s', 'LineWidth', 1.5, 'DisplayName', 'OTIS');
grid on;
xlabel('Data Point Index');
ylabel('Average AOA');
title('Comparison of Average AOA: OMEN vs OTIS', 'Interpreter', 'none');
legend('Location', 'best');
hold off;
