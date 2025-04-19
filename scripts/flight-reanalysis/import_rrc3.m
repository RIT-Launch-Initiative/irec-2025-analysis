function data = import_rrc3(file)
    arguments
        file (1,1) string {mustBeFile};
    end
    opts = delimitedTextImportOptions(NumVariables = 7, Delimiter = ",");
    opts.VariableNamesLine = 1;
    opts.VariableUnitsLine = 2;
    opts.DataLines = 3;
    opts.VariableTypes = ["double", "double", "double", "double", "double", "string", "double"];

    data = readtable(file, opts);
    data.Time = seconds(data.Time);
    event_locations = matches(data.Events, lettersPattern);
    event_table = eventtable(data.Time(event_locations), ...
        EventLabels = upper(data.Events(event_locations)));
    data.Events = [];
    
    data = table2timetable(data);
    data.Properties.Events = event_table;
end
