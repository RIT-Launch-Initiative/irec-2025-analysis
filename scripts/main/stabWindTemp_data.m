clear; close all;

addpath(genpath("C:\lmatlib"))

% Load the OTIS rocket file
otis_path = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end

% Initialize OpenRocket
otis = openrocket(otis_path);
sim = otis.sims("MATLAB");
opts = sim.getOptions();

% Configuration parameters
windSpeeds = 0:1:30;
temperature = 10:1:46;  % Now handles any number of temperatures
nSims = numel(windSpeeds);
nTemps = numel(temperature);

% Preallocate master data matrix
masterData = zeros(nSims, nTemps + 1);  % +1 for wind speed column
masterData(:,1) = windSpeeds';  % Transpose to column vector

% Simulation loop
for iTemp = 1:nTemps
    tSet = temperature(iTemp);
    stabOffRod = zeros(nSims, 1);  % Column vector for proper assignment
    
    for jWind = 1:nSims
        % Configure simulation
        opts.setWindSpeedAverage(windSpeeds(jWind));
        opts.setLaunchTemperature(tSet);
        
        % Run simulation and get data
        iSim = openrocket.simulate(sim, outputs="ALL");
        data = openrocket.get_data(sim);
        
        % Store stability margin at 0.26 seconds
        stabOffRod(jWind) = data{126, 'Stability margin'};
        disp(stabOffRod)
    end
    
    % Store results in corresponding temperature column
    masterData(:, iTemp + 1) = stabOffRod;
end


