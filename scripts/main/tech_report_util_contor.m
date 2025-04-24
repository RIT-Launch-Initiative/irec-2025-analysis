%% CONVERSION SHORT‑HANDS
m2ft  = 3.28084;
kg2lb = 2.20462;
ms2fts = 3.28084;

%% UNIT CONVERSIONS FOR PLOTTING
apogeeMat_ft = apogeeMat_m * m2ft;
M_lb  = noseMassVals * kg2lb;   % x‑axis (horizontal)
W_fts = windVals   * ms2fts;    % y‑axis (vertical)
[Wmesh, Mmesh] = meshgrid(W_fts, M_lb);

%% CONTOUR LEVELS
lo = floor(min(apogeeMat_ft(:))/250)*250;
hi = ceil(max(apogeeMat_ft(:))/250)*250;
levels = lo:250:hi;   % 250‑ft isolines

%% PLOT — MATCH REFERENCE STYLE
fig = figure('Color','w');
ax  = axes(fig);

% --- filled contour ---
contourf(Wmesh, Mmesh, apogeeMat_ft, levels, 'LineStyle','none');
colormap(ax, parula);

% --- overlay isolines + labels ---
hC = contour(Wmesh, Mmesh, apogeeMat_ft, levels, '-k', 'LineWidth', 0.75);
clabel(hC,'FontSize',8,'Color','k','LabelSpacing',300);

% --- NaN mask → black patch (for out‑of‑range domain) ---
mask = isnan(apogeeMat_ft);
if any(mask(:))
    hold on;
    contourf(Wmesh, Mmesh, double(mask), [0.5 0.5], 'FaceColor','k', 'LineStyle','none');
    hold off;
end

% --- axes / labels / title ---
axis tight;
ax.Layer = 'top';                 % grid on top of colours
ax.Box   = 'on';
ax.GridAlpha = 0.4;
grid(ax,'on');

xlabel(ax,'Wind Vel. [ft/s]');
ylabel(ax,'Mass [lb_m]');
title(ax,'Apogee [ft AGL] | Telemachus | White Sands');

% --- colour‑bar ---
cb = colorbar(ax);
cb.Label.String = 'Apogee [ft]';
cb.Ticks = levels(1:2:end);  % every other label to avoid clutter

%% (Optional) SAVE FIGURE
% exportgraphics(fig,'apogee_contour.png','Resolution',300);

