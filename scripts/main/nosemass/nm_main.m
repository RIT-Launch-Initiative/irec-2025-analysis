close all;
clear all;

%--------------- User parameters ---------------
step = 0.1;   % contour interval (kg)
%-----------------------------------------------

% assume windVals_mph, tempVals_C, massChart_kg are already in workspace
data_temps = 25:1:30;
data_winds = 4:1:7;

nT = numel(data_temps);   % rows = temps
nW = numel(data_winds);   % cols = winds

% pre-allocate
data_nmass      = zeros(nT, nW);        % continuous mass [kg]
pucks_g         = [1645 795 390 195 95 45];  % must match nm_getmass
nP              = numel(pucks_g);
data_puckCount  = zeros(nP, nT, nW);    % count of each puck type

% --- run sims with waitbar ---
wbar = waitbar(0, 'Running simulations...');
sim_num = 0;
nsims   = nT * nW;

for t = 1:nT
    for w = 1:nW
        sim_num = sim_num + 1;
        % grab both required mass AND puck list
        [m_req, puckList] = nm_getmass(data_temps(t), data_winds(w));
        data_nmass(t,w) = m_req;
        % count how many of each discrete puck we used
        for i = 1:nP
            data_puckCount(i, t, w) = sum( puckList == pucks_g(i) );
        end
        
        % update waitbar
        frac = sim_num / nsims;
        msg  = sprintf('Temp %.1f°C | Wind %.1f mph | Sim %d/%d', ...
                       data_temps(t), data_winds(w), sim_num, nsims);
        waitbar(frac, wbar, msg);
    end
end
close(wbar);

nm_contour;   
