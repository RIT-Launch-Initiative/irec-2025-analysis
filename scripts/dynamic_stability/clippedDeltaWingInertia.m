function I_y = clippedDeltaWingInertiaImperial(b, c, L_sweep, rho, t)
% clippedDeltaWingInertiaImperial calculates the mass moment of inertia
% of a clipped delta wing about the root chord axis in imperial units.
%
% Inputs:
%   b        - Total span of the unclipped wing (inches)
%   c        - Root chord length (inches)
%   L_sweep  - Sweep length (inches)
%   rho      - Material density (lb/in^3) (e.g., for aluminum: ~0.1 lb/in^3)
%   t        - Thickness of the wing (inches)
%
% Output:
%   I_y      - Moment of inertia about the root chord axis (slug·ft^2)

    % Conversion factors
    lbs_to_slugs = 1 / 32.174; % Convert pounds to slugs
    inches_to_feet = 1 / 12;   % Convert inches to feet

    % Calculate the effective span and area
    b_effective = b - 2 * L_sweep; % Effective span after clipping (inches)
    area_total = 0.5 * c * b_effective; % Area of the clipped delta wing (in^2)

    % Calculate the volume and mass
    volume_total = area_total * t; % Volume of the wing (in^3)
    mass_total_lbs = rho * volume_total; % Total mass in pounds
    mass_total_slugs = mass_total_lbs * lbs_to_slugs; % Convert mass to slugs

    % Calculate the moment of inertia for the main triangular section
    % Note: Inertia in in^4, converted to slug·ft^2
    I_triangle = (1/18) * mass_total_slugs * (b_effective * inches_to_feet)^2;

    % Calculate the moment of inertia for the swept regions
    area_sweep = L_sweep * (c / 2); % Area of one swept rectangular section (in^2)
    volume_sweep = area_sweep * t; % Volume of one swept section (in^3)
    mass_sweep_lbs = rho * volume_sweep; % Mass of one swept section (lbs)
    mass_sweep_slugs = mass_sweep_lbs * lbs_to_slugs; % Convert to slugs
    I_sweep = (1/12) * mass_sweep_slugs * (L_sweep * inches_to_feet)^2; % Convert to slug·ft^2

    % Total moment of inertia (subtracting the swept regions)
    I_y = I_triangle - 2 * I_sweep;
end
