otis_path = "IREC_2025_M6000ST-0.ork"; %pfullfile("samples", "data", "OMEN.ork");

%% Basic plots
omen = openrocket(omen_path);
sim = omen.sims(1); % get simulation by number

drogue = omen.component(name = "Streamer"); % get streamer 
event = openrocket.get_deploy(drogue, sim); % get event for drogue chute
event.setDeployDelay(3); % 3-second drogue delay

openrocket.simulate(sim); % execute simulation
data = openrocket.get_data(sim); % get all of the simulation's outputs
% equivalently, data = openrocket.simulate(sim, outputs = "ALL") will do the same thing

plot_openrocket(data, "Stability margin", "Angle of attack", ...
    start_ev = "LAUNCHROD", end_ev = "APOGEE", labels = ["LAUNCHROD", "BURNOUT"]);
