%% ── OVERLAY HISTOGRAMS ─────────────────────────────────────────────────
figure; hold on;
cols  = [1 0.3 0.3;  0.3 0.3 1.0;  0.3 0.8 0.3;  1 0.6 0.1]; % extend if >4

for s = 1:numel(params)
    histogram(error_from_10k{s}-658, ...
        'FaceColor',cols(s,:), ...
        'FaceAlpha',0.5, ...
        'DisplayName',params(s).label);
end
xlabel("Apogee deviation from 10 000 ft (ft)");
ylabel("Simulation count");
title("Apogee Error – Atmospheric Model Comparison");
legend show; grid on; box on; set(gca,'FontSize',14);
hold off;

