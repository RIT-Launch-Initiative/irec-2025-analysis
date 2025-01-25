clear; close all;

addpath(genpath("C:\\lmatlib"))

% Load the OTIS rocket file
otis_path = "C:\\irec-2025-analysis\\IREC_2025_M6000ST-0.ork";
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end

% Initialize OpenRocket
otis = openrocket(otis_path);
sim = otis.sims("MATLAB");
opts = sim.getOptions();


%set config
nSims = 100;
turbIntesity = 1;
opts.setWindTurbulenceIntensity(.15)
opts.setWindSpeedAverage(10*0.447); 
opts.setLaunchTemperature(25 + 273.15);  % 25°C
stabOffRod = zeros(nSims,2);


for I = 1:nSims      
    % Run single simulation
    iSim = openrocket.simulate(sim, outputs="ALL");
    
    % Retrieve simulation data
    data = openrocket.get_data(sim);
    curStability = data{126, "Stability margin"};
    stabOffRod (I,1) = curStability;
    disp(curStability)
    % curWindSpeed = data{126,"Wind velocity"};
    % stabOffRod (I,2) = curWindSpeed;
    % disp(curWindSpeed)

    %set the seed to random
    opts.randomizeSeed 

end


figure
histogram(stabOffRod)







