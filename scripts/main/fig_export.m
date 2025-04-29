function fig_export(fileName)
%FIG_EXPORT  Export figure(1) to PDF in a fixed directory.
%   fig_export(fileName) saves the axes (gca) of figure(1)
%   to 'C:\irec-2025-analysis\tech_report_figs\fileName.pdf'

    outDir = 'C:\irec-2025-analysis\tech_report_figs';

    % make sure folder exists
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    % select fig 1 and grab its axes
    fig1 = figure(1);
    ax   = gca;

    % export as vector PDF
    exportgraphics(ax, fullfile(outDir, fileName), 'ContentType', 'vector');
end
