function mass_opt = tune_nose_mass
% ---------- one-time prep ----------
otis = openrocket("IREC_2025_M6000ST-0.ork");
sim  = otis.sims("10MPH-TEXAS-36C-(TYP)");
cmp  = otis.component('name','Adjustable stability weight(s)');

site = launchsites("spaceport-midland");
lt   = datetime(2024,06,21,10,21,0,'TimeZone','MST');
air  = atmosphere("gfs","pgrb2.1p00",site.lat,site.lon,lt,minpres=450);
air.TMP = air.TMP + 273.15;                         % °C → K

goal = 3048;         % apogee target [m]
x0   = 1.2;         % initial guess [kg]

% ---------- search ----------
mass_opt = fminsearch(@cost,x0);
fprintf("best mass %.3f kg  →  apogee %.1f m\n",mass_opt,fly(mass_opt));

% -- save to OR --
otis = openrocket("C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork");
cmp  = otis.component('name','Adjustable stability weight(s)');
cmp.setComponentMass(mass_opt);
otis.save()


% ---------- helpers ----------
    function err = cost(m)
        err = (fly(m) - goal)^2;                    % squared error
    end

    function apo = fly(m)
        cmp.setComponentMass(m);                    % tweak mass
        d = otis.simulate(sim,outputs="Air pressure",...
                              atmos=air(:,["HGT","PRES","TMP"]));
        h = pressalt("m",d.("Air pressure"),"Pa") ...
            - pressalt("m",d{1,"Air pressure"},"Pa");
        apo = max(h);                               % apogee
    end
end
