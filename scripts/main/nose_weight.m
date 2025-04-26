% This script will collect all of the data in various scripts for you and
% collect it
close all;clear; 


addpath(genpath("C:\\lmatlib"))
addpath(genpath("C:\lmatlib\sim"));

% open rocket integration intitialize 
otis_path = "C:\\irec-2025-analysis\\IREC_2025_M6000ST-0.ork";
otis = openrocket(otis_path);
sim = otis.sims("15MPH-TEXAS-36C-(TYP)"); %from openrocket
if ~isfile(otis_path)
    error("No document '%s' found. Ensure the path is correct.", otis_path);
end

% open rocket integration config
opts = sim.getOptions();

NoseWeight = otis.component(name="Adjustable stability weight");
NoseWeight = NoseWeight.getMass();

% needs to be in descending order
pucks= [1000 750 500 500 250 250 100 100 50 25 25 10];
target = NoseWeight;
weight_combo = [];
count = 1;

for i = pucks
 if (1000*target - i) > 0
     weight_combo(count) = i;
     target = target-0.001*i;
 end
     count = count +1;
end

weight_combo = nonzeros(weight_combo)




