function [maxAltitudes] = apogeeTemp(temperatures,simName,turbIntensity,windSpeed,otis_path)

    % Load the OTIS rocket file
    if ~isfile(otis_path)
        error("No document '%s' found. Ensure the path is correct.", otis_path);
    end
    
    % Initialize OpenRocket
    otis = openrocket(otis_path);
    sim = otis.sims(simName);
    opts = sim.getOptions();
    
    
    % Configuration parameters
    opts.setWindTurbulenceIntensity(turbIntensity);
    nTemps = numel(temperatures);
    
    % Preallocate array for maximum altitudes
    maxAltitudes = zeros(nTemps, 1);
    
    % Simulation loop
    for iTemp = 1:nTemps
        tSet = temperatures(iTemp)+273.15;
        
        % Configure simulation
        opts.setWindSpeedAverage(windSpeed);
        opts.setLaunchTemperature(tSet);  % Convert Celsius to Kelvin
        
        % Run simulation and get data
        iSim = openrocket.simulate(sim, outputs="ALL");
        data = openrocket.get_data(sim);
        
        % Store maximum altitude
        maxAltitudes(iTemp) = max(data.Altitude);
    end

end