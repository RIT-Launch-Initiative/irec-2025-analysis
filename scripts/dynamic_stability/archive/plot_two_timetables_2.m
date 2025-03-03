% MATLAB Script to plot Angle of Attack vs Time from two timetables
% Assumes you have two timetables: timetable1 and timetable2

% Load timetables from OpenRocket CSV files
% Replace 'path1' and 'path2' with the actual file paths
path1 = 'C:\Users\jss26\Downloads\otis_aoa.csv';
path2 = 'C:\Users\jss26\Downloads\omen_aoa.csv';

% Import the data using the import_openrocket_simdata function
timetable1 = import_openrocket_simdata(path1, 'verbose', true);
timetable2 = import_openrocket_simdata(path2, 'verbose', true);

% Plotting the timetables
figure;

% Plot first timetable
plot(timetable1.Time, timetable1.AngleOfAttack, '-o', 'DisplayName', 'Timetable 1', 'LineWidth', 1.5);
hold on;

% Plot second timetable
plot(timetable2.Time, timetable2.AngleOfAttack, '-x', 'DisplayName', 'Timetable 2', 'LineWidth', 1.5);

% Axis labels and title
xlabel('Time');
ylabel('Angle of Attack (deg)');
title('Angle of Attack vs Time');

% Add legend
legend;

grid on;
hold off;

%% Function to import OpenRocket simulation data into a timetable
function timetab = import_openrocket_simdata(path, opts)
    arguments
        path (1,1) string;
        opts.verbose (1,1) logical = false;
    end
    lines = readlines(path);

    assert(startsWith(lines(1), "#"), "Incorrect comment character: expected #");

    %% Create header
    header_sw = "# Time";
    header_fmt = "(?<name>[A-Z].*) \((?<unit>.*)\)"; % column header format (regex)
    % captures "<Name> (<unit>)"

    head_line_n = find(startsWith(lines, header_sw), 1, "first");
    if opts.verbose 
        fprintf("Header found at line %d\n", head_line_n);
    end
    head_strings = split(lines(head_line_n), ",");
    head_matches = regexp(head_strings, header_fmt, "names");
    not_matching = cellfun(@isempty, head_matches);

    if any(not_matching)
        error("Could not match column header(s) %s:\n\t%s\n", ...
            mat2str(find(not_matching)'), mat2str(head_strings(not_matching)'));
    end
    
    headers = struct2table([head_matches{:}]);

    % Modify header for special variables
    ssm_idx = headers.name == "Stability margin calibers";
    headers.name(ssm_idx) = "Stability margin";
    headers.unit(ssm_idx) = "cal";

    % get rid of special characters
    headers.unit(headers.unit == "°") = "deg";
    headers.unit(headers.unit == "​") = "-";

    % status output
    if opts.verbose 
        fprintf("Recognized %d columns and units\n\n", length(headers.name));
        disp(headers);
    end
    
    %% Get data
    tab = readtable(path, CommentStyle = "#");
    if opts.verbose 
        fprintf("Read %d rows of data.\n", height(tab));
    end

    tab.Properties.VariableNames = headers.name;
    tab.Properties.VariableUnits = headers.unit;

    % convert numbers to times
    for i = find(headers.unit == "s")'
        tab.(i) = seconds(tab.(i));
    end
    for i = find(headers.unit == "min")'
        tab.(i) = minutes(tab.(i));
    end

    timetab = table2timetable(tab);

    %% Get event times
    event_sw = "# Event";
    event_fmt = "# Event ([A-Z_]+) occurred at t=([\d.]+) seconds"; % event line format (regex)
    % captures "Event <EVENT_NAME> occurred at t=<1234.56> seconds"

    event_strings = lines(startsWith(lines, event_sw));
    event_matches = regexp(event_strings, event_fmt, "tokens");
    event_count = length(event_matches);

    if isempty(event_strings)
        error("No events detected");
    end
    
       % unpack cell array from event_matches into name and time arrays
    ev_names = strings(event_count, 1); 
    ev_times = duration(NaN(event_count, 3));
    for i = 1:event_count
        if isempty(event_matches{i})
            warning('Failed to match name and time in event %d: "%s"', ...
                i, event_strings(i));
        else 
            pair = event_matches{i}{1};
            ev_names(i) = pair(1);

            % find closest time to t=...
            % because of roundoff (or other things), event time might not exactly match table time
            ev_time_raw = seconds(str2double(pair(2)));
            [~, ev_idx] = min(abs(timetab.Time - ev_time_raw)); % closest time
            ev_times(i) = timetab.Time(ev_idx);
        end
    end


    %% Name recovery devices
    reco_evname = "RECOVERY_DEVICE_DEPLOYMENT";

    is_reco = ev_names == reco_evname;
    switch sum(is_reco)
        case 0
            warning("Did not find %s", reco_evname);
        case 1
            ev_names(is_reco) = "MAIN";
            if opts.verbose
                fprintf("Converted one %s to MAIN at %.2f seconds\n", ...
                    reco_evname, seconds(ev_times(is_reco)));
            end
        case 2
            reco_name_order = ["DROGUE"; "MAIN"];
            ev_names(is_reco) = reco_name_order;
            reco_times = seconds(ev_times(is_reco));
            if opts.verbose
                fprintf("Converted first %s to %s at %.2f seconds\n", ...
                    reco_evname, reco_name_order(1), reco_times(1));
                fprintf("Converted second %s to %s at %.2f seconds\n", ...
                    reco_evname, reco_name_order(2), reco_times(2));
            end
        otherwise
            ats = compose("\tat %.2f seconds", seconds(ev_times(is_reco)));
            warning("Cannot disambiguate %d deployment events\n%s", ...
                sum(is_reco), join(ats, newline));
    end


    event_table = table(ev_times, 'VariableNames', {'EventTimes'}); event_table.EventLabels = ev_names;
    if opts.verbose 
        fprintf("Recognized %d events\n\n", height(event_table));
        disp(event_table);
    end

    if numel(ev_names) ~= numel(unique(ev_names))
        warning("Non-unique event names cannot be used to delimit plot bounds");
    end

    %% Assign metadata
    timetab.Properties.Events = event_table;
    timetab.Properties.VariableContinuity = repmat("continuous", 1, width(timetab));

    % Identify this as an OpenRocket import
    timetab.Properties.Description = "openrocket";
end
