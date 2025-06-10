%% CREATE_AIRDATA_FILES.M
% Pull GFS atmosphere data for a launch window and save each snapshot
% as its own .mat file in ./airdata_cache/.

clear; clc;

% --- settings you might change ------------------------------------------------
site_name           = "spaceport-midland";      % launch site in your launchsites()
nominal_launch_time = datetime(2025,06,11,12,0,0,'TimeZone','-05:00');
time_window_hours   = 5;                       % ± range
time_step_hours     = 1;                        % resolution
ref_time            = datetime('now','TimeZone','-05:00') - hours(6);
cache_dir           = fullfile(pwd,'scripts\irec\airdata_cache\wed');
% ------------------------------------------------------------------------------
if ~isfolder(cache_dir), mkdir(cache_dir); end
site = launchsites(site_name);

launch_window = nominal_launch_time + ...
                hours(-time_window_hours:time_step_hours:time_window_hours);

fprintf("Caching %d atmosphere snapshots to %s\n",numel(launch_window),cache_dir);

for i = 1:numel(launch_window)
    t          = launch_window(i);
    fname      = fullfile(cache_dir, ...
                   sprintf('airdata_%s.mat',datestr(t,'yyyymmdd_HHMM')));
    try
        airdata = atmosphere("nam","awphys",site.lat,site.lon,t, ...
                             minpres=450,reftime=ref_time);
        save(fname,'airdata');                % overwrite if it exists
        fprintf("✓ %s saved\n",fname);
    catch ME
        warning("× failed (%s) – %s",datestr(t),ME.message);
    end
end
