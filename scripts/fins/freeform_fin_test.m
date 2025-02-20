clear; close all;

ork_file_path = "C:\irec-2025-analysis\IREC_2025_M6000ST-0.ork";
addpath(genpath("C:\lmatlib\sim"));

% Name of the OpenRocket simulation to run
sim_name = "15MPH-TEXAS-36C-(TYP)";

otis = openrocket(ork_file_path);

% Retrieve the simulation by name
sim = otis.sims(sim_name);

% Retrieve the existing fin set
fins = otis.component(class="FinSet");
if isempty(fins)
    error("No FinSet found in the rocket file!");
end

% Retrieve the initial fin points (assumed in 3D; fin geometry is defined in a 2D plane)
pointsJava = fins.getFinPointsWithRoot;
N = length(pointsJava);
xArr = zeros(1, N);
yArr = zeros(1, N);
zArr = zeros(1, N);

for i = 1:N
    c = pointsJava(i);
    xArr(i) = c.x;  % or c.getX()
    yArr(i) = c.y;  % or c.getY()
    zArr(i) = c.z;  % or c.getZ()
    fprintf("Point %d => X=%.5f, Y=%.5f, Z=%.5f\n", i, xArr(i), yArr(i), zArr(i));
end

%% Insert a new point to curve the fin between the first and second original points.
% The documentation states that addPoint(index, location) inserts a point between
% indices (index-1) and index. In the underlying Java code, points are 0-indexed.
% To insert between the first (index 0) and second (index 1) points, call addPoint(1, newLocation).
index = 1;  % Insert before the current fin point at Java index 1

% Work in 2D (X, Y) for the fin shape.
x1 = xArr(1); y1 = yArr(1);
x2 = xArr(2); y2 = yArr(2);

% Compute the midpoint of the segment between the first two points.
midX = (x1 + x2) / 2;
midY = (y1 + y2) / 2;

% Determine the segment vector.
dx = x2 - x1;
dy = y2 - y1;
segmentLength = sqrt(dx^2 + dy^2);

% Compute a perpendicular vector.
% Previously we used (-dy, dx); if that curves the fin inward,
% try the reverse (dy, -dx) to push the new point outward.
perpX = dy;
perpY = -dx;
% Normalize the perpendicular vector.
perpNorm = sqrt(perpX^2 + perpY^2);
perpX = perpX / perpNorm;
perpY = perpY / perpNorm;

% Choose an offset magnitude (adjust this factor to change the curvature).
offsetMagnitude = 0.1 * segmentLength;

% Compute the new location by offsetting the midpoint.
newX = midX + offsetMagnitude * perpX;
newY = midY + offsetMagnitude * perpY;

% Create the new fin point as a Java Point2D.Double object.
newLocation = javaObject('java.awt.geom.Point2D$Double', newX, newY);

% Add the new point between the appropriate indices.
fins.addPoint(index, newLocation);
fprintf("Added new curved fin point at (%.5f, %.5f) between the original first and second points.\n", newX, newY);

%% Retrieve the updated fin points after modification.
pointsJava = fins.getFinPointsWithRoot;
N = length(pointsJava);
xArr = zeros(1, N);
yArr = zeros(1, N);
zArr = zeros(1, N);
for i = 1:N
    c = pointsJava(i);
    xArr(i) = c.x;
    yArr(i) = c.y;
    zArr(i) = c.z;
    fprintf("Updated Point %d => X=%.5f, Y=%.5f, Z=%.5f\n", i, xArr(i), yArr(i), zArr(i));
end

% Close the fin shape by appending the first point at the end.
xArr(end+1) = xArr(1);
yArr(end+1) = yArr(1);
zArr(end+1) = zArr(1);

%% Plot the updated (curved) fin shape in 3D.
figure;
plot3(xArr, yArr, zArr, '-o', 'LineWidth', 2, 'MarkerSize', 6);
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Updated Curved Fin Shape');
grid on;
axis equal;
