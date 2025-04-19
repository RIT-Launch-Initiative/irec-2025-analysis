function [dx, dy] = latlon2deltaxy(origin, point)
    arguments
        origin struct;
        point struct;
    end

    R = 6370e3; % [m] Earth mean radius
    dy = deg2rad(point.lat - origin.lat) * R;
    dx = deg2rad(point.lon - origin.lon) * R * cosd(origin.lat);
end

