% MATLAB script to calculate the optimal fin shape for a desired stability margin

% Clear workspace and command window
clear;
clc;

% Input rocket parameters without fins
L = input('Enter the rocket length (m): ');
D = input('Enter the rocket body diameter (m): ');
mass = input('Enter the rocket mass without fins (kg): ');
CG_no_fins = input('Enter the CG location without fins from nose tip (m): ');
CP_no_fins = input('Enter the CP location without fins from nose tip (m): ');

% Desired stability margin (in calibers)
desired_margin = input('Enter the desired stability margin (in calibers): ');

% Material properties (density in kg/m^3)
materials = {'Balsa', 'Plywood', 'Fiberglass', 'Carbon Fiber'};
disp('Select material:');
for i = 1:length(materials)
    fprintf('%d. %s\n', i, materials{i});
end
material_choice = input('Enter material number: ');
material = materials{material_choice};

switch material
    case 'Balsa'
        density = 160;
    case 'Plywood'
        density = 600;
    case 'Fiberglass'
        density = 1850;
    case 'Carbon Fiber'
        density = 1750;
end

% Number of fins
N = input('Enter the number of fins (e.g., 3 or 4): ');

% Fin thickness (assumed constant)
t = input('Enter the fin thickness (m): ');

% Default fin parameters (initial guesses)
Cr_default = 0.1 * L;  % Root chord length (m)
Ct_default = 0.5 * Cr_default; % Tip chord length (m)
h_default = 0.1 * L; % Fin height (m)
Ls_default = (Cr_default - Ct_default) / 2; % Sweep length (m)

% Ranges for fin parameters
Cr_range = [0.05*L, 0.2*L];
Ct_range = [0.2*Cr_default, 0.8*Cr_default];
h_range = [0.05*L, 0.2*L];
Ls_range = [0, (Cr_default - Ct_default)];

% Discretize the ranges
Cr_values = linspace(Cr_range(1), Cr_range(2), 20);
Ct_values = linspace(Ct_range(1), Ct_range(2), 20);
h_values = linspace(h_range(1), h_range(2), 20);
Ls_values = linspace(Ls_range(1), Ls_range(2), 20);

% Initialize variables to store optimal values
min_diff = inf;

% Iterate over possible fin dimensions to find the optimal shape
for Cr = Cr_values
    for Ct = Ct_values
        for h = h_values
            for Ls = Ls_values
                % Fin area (assuming trapezoidal fin)
                S = 0.5 * (Cr + Ct) * h;

                % Fin mass
                fin_volume = S * t;
                fin_mass = fin_volume * density;
                total_fin_mass = N * fin_mass;

                % Total mass
                total_mass = mass + total_fin_mass;

                % Fin CP location (Barrowman method)
                x_r = L - Cr; % Fin root position from nose tip
                x_fins = x_r + (Cr + Ct) / 3 * (Cr + 2 * Ct) / (Cr + Ct); % Fin CP

                % Overall CP location
                CP = (CP_no_fins * mass + x_fins * N * S) / (mass + N * S);

                % Fin CG location (approximate)
                fin_CG = x_r + (Cr + 2 * Ct) / (3 * (Cr + Ct)) * h;

                % Overall CG location
                CG_with_fins = (mass * CG_no_fins + total_fin_mass * fin_CG) / total_mass;

                % Stability margin
                stability_margin = (CP - CG_with_fins) / D;

                % Compare to desired margin
                diff = abs(stability_margin - desired_margin);

                if diff < min_diff
                    min_diff = diff;
                    optimal_Cr = Cr;
                    optimal_Ct = Ct;
                    optimal_h = h;
                    optimal_Ls = Ls;
                    optimal_stability_margin = stability_margin;
                    optimal_CG = CG_with_fins;
                    optimal_CP = CP;
                    optimal_fin_mass = total_fin_mass;
                end
            end
        end
    end
end

% Display optimal fin parameters
fprintf('\nOptimal Fin Parameters:\n');
fprintf('Root chord length (Cr): %.4f m\n', optimal_Cr);
fprintf('Tip chord length (Ct): %.4f m\n', optimal_Ct);
fprintf('Fin height (h): %.4f m\n', optimal_h);
fprintf('Sweep length (Ls): %.4f m\n', optimal_Ls);
fprintf('Number of fins (N): %d\n', N);
fprintf('Fin thickness (t): %.4f m\n', t);
fprintf('Material: %s\n', material);

% Display results
fprintf('\nResults:\n');
fprintf('Optimal stability margin: %.4f calibers\n', optimal_stability_margin);
fprintf('CG location with fins: %.4f m\n', optimal_CG);
fprintf('CP location with fins: %.4f m\n', optimal_CP);
fprintf('Total fin mass: %.4f kg\n', optimal_fin_mass);

% Plot fin shape
x_coords = [0, optimal_Cr, optimal_Cr - optimal_Ls, -optimal_Ls, 0];
y_coords = [0, 0, optimal_h, optimal_h, 0];

figure;
plot(x_coords, y_coords, 'b-', 'LineWidth', 2);
axis equal;
title('Optimal Fin Shape');
xlabel('Length (m)');
ylabel('Height (m)');
grid on;
