function [stabOffRod,timeToStability] = stabWindTemp (windSpeeds,otis_path,simName)
      
    nSims = numel(windSpeeds);

    % Initialize OpenRocket
    otis = openrocket(otis_path);
    sim = otis.sims(simName);
    opts = sim.getOptions();
    
    % Preallocate master data matrix
    stabOffRod = zeros(nSims,1);  % +1 for wind speed column

    timeToStability = zeros(nSims,1);
    
    % Simulation loop
    for jWind = 1:nSims

        % Configure simulation
        opts.setWindSpeedAverage(windSpeeds(jWind));
        
        % Run simulation and get data
        iSim = openrocket.simulate(sim, outputs="ALL");
        data = openrocket.get_data(sim);
        
        %trim data
        data_range = timerange(eventfilter("LAUNCHROD"), eventfilter("BURNOUT"), "openleft");
        data = data(data_range, :);
            
        % Check stability margin and time
        stabilityMargin = data{:, 'Stability margin'};
    
        % Store stability margin at launchrod
        stabOffRod(jWind) = stabilityMargin(1,1);
              
        if stabOffRod(jWind) >= 1.5
            timeToStability(jWind) = 0;
        else
            % Define the subarray starting at index 127
            marginSubarray = stabilityMargin(1:end);
            timeSubarray = seconds(data.Time(1:end));

            if any(marginSubarray >= 1.5)% Find the index range where stabilityMargin crosses 1.5
                % Use interp1 to find the exact time where stabilityMargin reaches 1.5
                timeToStability(jWind) = (interp1(marginSubarray, timeSubarray, 1.5))-(timeSubarray(1,1));
            else
                timeToStability(jWind) = NaN;  % No stability achieved
            end    
        end
        disp = 'Stability %4.3f cal, at wind speed %4.1f, sim number %4.0f, time to stability: %4.3f s\n';
        fprintf(disp, stabOffRod(jWind), windSpeeds(jWind), jWind, timeToStability(jWind));
    end 