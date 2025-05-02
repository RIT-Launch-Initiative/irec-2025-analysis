close all;
clear all;

%--------------- User parameters ---------------
step = 0.1;   % contour interval (kg)
%-----------------------------------------------

% assume windVals_mph, tempVals_C, massChart_kg are already in workspace
data_temps = 20:1:35;
data_winds = 4:1:10;

nT = numel(data_temps);   % 16
nW = numel(data_winds);   % 7
data_nmass = zeros(nT, nW);   % 16 × 7  (rows = temps, cols = winds)


% --- create bar ---
wbar = waitbar(0, 'Running simulations...');

sim_num = 0;                       % counter for progress
nsims   = nT * nW;                 % total number of sims

for t = 1:nT
    for w = 1:nW
        sim_num = sim_num + 1;     % update progress counter
        
        % run the simulation
        data_nmass(t, w) = nm_getmass(data_temps(t), data_winds(w))
        
        % progress fraction and custom message
        frac = sim_num / nsims;
        msg  = sprintf('Temp %.1f °C | Wind %.1f mph | Sim %d of %d', ...
                       data_temps(t), data_winds(w), sim_num, nsims);
        
        % update waitbar
        waitbar(frac, wbar, msg);
    end
end

close(wbar);

nm_contour;