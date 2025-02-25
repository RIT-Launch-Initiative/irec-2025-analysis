% Fin Flutter Speed Calculation with LaTeX Output
% Define Parameters
rho = 1.225;              % Air density (kg/m^3)
E = 70e9;                 % Young's Modulus of fin material (Pa)
G = 26e9;                 % Shear Modulus of fin material (Pa)
thickness = 0.005;        % Thickness of fin (m)
chord = 0.2;              % Chord length of fin (m)
span = 0.5;               % Span of fin (m)
mass_per_area = 10;       % Mass per unit area (kg/m^2)

% Derived Parameters
I = (thickness^3 * chord) / 12;       % Area moment of inertia (m^4)
S = chord * span;                     % Planform area (m^2)
k_alpha = G * thickness * chord / 2;  % Torsional rigidity (Nm^2)

% Flutter Speed Calculation
V_f = sqrt((pi^2 * E * I) / (rho * S * k_alpha));  % Flutter velocity (m/s)

% LaTeX File Output
fileID = fopen('fin_flutter_calculation.tex', 'w');
fprintf(fileID, '\documentclass{article}\n');
fprintf(fileID, '\usepackage{amsmath}\n');
fprintf(fileID, '\begin{document}\n');
fprintf(fileID, '\title{Fin Flutter Speed Calculation}\n');
fprintf(fileID, '\author{MATLAB Generated Report}\n');
fprintf(fileID, '\date{\today}\n');
fprintf(fileID, '\maketitle\n');
fprintf(fileID, '\section*{Parameters}\n');
fprintf(fileID, '\begin{itemize}\n');
fprintf(fileID, '\item Air density, $\rho = %.3f$ kg/m$^3$\n', rho);
fprintf(fileID, '\item Shear Modulus, $G = %.2e$ Pa\n', G);
fprintf(fileID, '\item Thickness of fin, $t = %.3f$ m\n', thickness);
fprintf(fileID, '\item Chord length, $c = %.2f$ m\n', chord);
fprintf(fileID, '\item Span of fin, $s = %.2f$ m\n', span);
fprintf(fileID, '\item Mass per unit area, $m = %.2f$ kg/m$^2$\n', mass_per_area);
fprintf(fileID, '\end{itemize}\n');
fprintf(fileID, '\section*{Derived Parameters}\n');
fprintf(fileID, '\begin{itemize}\n');
fprintf(fileID, '\item Area moment of inertia, $I = %.2e$ m$^4$\n', I);
fprintf(fileID, '\item Planform area, $S = %.2f$ m$^2$\n', S);
fprintf(fileID, '\item Torsional rigidity, $k_\alpha = %.2e$ Nm$^2$\n', k_alpha);
fprintf(fileID, '\end{itemize}\n');
fprintf(fileID, '\section*{Flutter Speed Calculation}\n');
fprintf(fileID, 'The estimated fin flutter speed is given by:\\[10pt]\n');
fprintf(fileID, '\begin{equation}\n');
fprintf(fileID, 'V_f = \sqrt{\frac{\pi^2 E I}{\rho S k_\alpha}}\n');
fprintf(fileID, '\end{equation}\n');
fprintf(fileID, 'Substituting the values, we get:\\[10pt]\n');
fprintf(fileID, '\begin{equation}\n');
fprintf(fileID, 'V_f = %.2f \text{ m/s}\n', V_f);
fprintf(fileID, '\end{equation}\n');
fprintf(fileID, '\end{document}\n');
fclose(fileID);

% Display Result
fprintf('Estimated Fin Flutter Speed: %.2f m/s\n', V_f);
