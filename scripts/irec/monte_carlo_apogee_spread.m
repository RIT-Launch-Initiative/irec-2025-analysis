figure
histogram((data_apogee*3.28084)-10700,12,'FaceColor', [1 0.2 0.2])
title("Apogee Error With Inccurate Atmosphereic Condtion Ranges");
xlabel("Apogee Difference from 10,000 ft")
ylabel("Simulatin Count")
