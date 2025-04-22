outDir = 'C:\irec-2025-analysis\tech_report_figs';
fig1 = figure(1);
ax   = gca;
figname = "montecarloaoa.pdf";
exportgraphics(ax, fullfile(outDir,figname), 'ContentType','vector');