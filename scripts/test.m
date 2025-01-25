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
nSims = 10;
figure;
turbIntesity = 1;
opts.setWindTurbulenceIntensity(15)
opts.setWindSpeedAverage(6.7); 
opts.setLaunchTemperature(25 + 273.15);  % 25°C
stabOffRod = zeros(nSims,2);


for I = 1:nSims      
    % Run single simulation
    iSim = openrocket.simulate(sim, outputs="ALL");
    
    % Retrieve simulation data
    data = openrocket.get_data(sim);
    curStability = data{126, "Stability margin"};
    stabOffRod (I,1) = curStability;
    curWindSpeed = data{126,"Wind velocity"};
    stabOffRod (I,2) = curWindSpeed;
    
    % 
    % plot3(data.("Position East of launch")*3.28084, ...
    %   data.("Position North of launch")*3.28084, ...
    %   data.Altitude*3.28084, 'LineWidth', 1.5);
    % hold on;
    % grid on;
end

% view(3);
% xlabel('Position East (ft)');
% ylabel('Position North (ft)');
% zlabel('Altitude (ft)');
% title('3D Trajectory (15mph,10%turb))');

figure
histogram(stabOffRod)







