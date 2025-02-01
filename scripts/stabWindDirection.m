function [stabOffRod,windOffRod] = stabWindDirection(simName,nSims,turbIntensity,windSpeed,otis_path,temp)
    addpath(genpath("C:\\lmatlib"))
    % Load the OTIS rocket file
    if ~isfile(otis_path)
        error("No document '%s' found. Ensure the path is correct.", otis_path);
    end
    
    % Initialize OpenRocket
    otis = openrocket(otis_path);
    sim = otis.sims(simName);
    opts = sim.getOptions();
    
    %set config
    opts.setWindTurbulenceIntensity(turbIntensity)
    opts.setWindSpeedAverage(windSpeed); 
    opts.setLaunchTemperature(temp);  % 25°C
    opts.set
    stabOffRod = zeros(nSims,1);
    windOffRod = zeros(nSims,1);
    
    
    for I = 1:nSims      
        % Run single simulation
        iSim = openrocket.simulate(sim, outputs="ALL");
        
        % Retrieve simulation data
        data = openrocket.get_data(sim);
        curStability = data{126, "Stability margin"};
        stabOffRod (I,1) = curStability;
        
        curWindSpeed = data{126,"Wind velocity"};
        windOffRod (I,1) = curWindSpeed;
     
    
        %set the seed to random
        opts.randomizeSeed



        formatSpec = '%4.2f cal at %8.3f m/s, nSim#:%4.0f\n';
        fprintf(formatSpec,curStability,curWindSpeed,I)
    
    end
  
end





