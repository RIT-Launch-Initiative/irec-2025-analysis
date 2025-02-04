function [launchAngles,maxAltitudes] = angleApogee (angleStep,high_angle,low_angle,simName,turbIntensity,windSpeed,otis_path)
    
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
    minAngle = 90-high_angle;
    maxAngle = 90-low_angle;
    launchAngles = (deg2rad(minAngle)):(deg2rad(angleStep)):(deg2rad(maxAngle));
    nAngles = numel(launchAngles);
    
    % Preallocate array for maximum altitudes
    maxAltitudes = zeros(nAngles, 1);
    
    % Simulation loop
    for iAngle = 1:nAngles
        angleSet = launchAngles(iAngle);
        
        % Configure simulation
        opts.setWindSpeedAverage(windSpeed);
        opts.setLaunchTemperature(36 + 273.15);  % Convert Celsius to Kelvin
        opts.setLaunchRodAngle(angleSet)
        opts.setLaunchAltitude(1828);% Launch altitude in meters
        
        % Run simulation and get data
        iSim = openrocket.simulate(sim, outputs="ALL");
        data = openrocket.get_data(sim);
        
        % Store maximum altitude (convert meters to feet)
        maxAltitudes(iAngle) = max(data.Altitude) * 3.28084;
    end

end

