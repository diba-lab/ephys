function [] = zone_to_ttl(folder,debug)
% Function to ID track and zones to trigger TTL out pulses

if nargin < 2
    debug = false;
end
clear global
global D2value
global D4value
global zone_sum
global pos
global pos_opti
global pos_lin
global time_opti
global time_mat
global trig_on
global save_loc
global SR
global a
global on_minutes  % Marker for on and minutes
global hl
D2value = 0; D4value = 0;
zone_sum = 0;

save_loc = fullfile(folder, ['recording_' datestr(now,1) '.mat']);
while exist(save_loc,'file')
    if ~strcmpi(save_loc(end-5),'-')
        save_loc = fullfile(folder, ['recording_' datestr(now,1) '-1.mat']);
    elseif strcmpi(save_loc(end-5),'-')
        curr_version = str2num(save_loc(end-4));
        save_loc = fullfile(folder, ['recording_' datestr(now,1) '-' num2str(curr_version+1) '.mat']);
    end
end

run_time = 180*60; %seconds
SR = 20; %Hz

% Construct pos vector to keep track of last 0.25 seconds
nquarter = ceil(SR/4); % #samples in a quarter second
pos = repmat([0 0 -500], nquarter, 1); % Start pos with z-position waaaay off
pos_opti = [];
pos_lin = [nan; nan];
time_opti = [];
time_mat = [];
trig_on = [0; 0];
on_minutes = [false; false];

% Make sure track is aligned with z axis in optitrack calibration first!
% Connect to optitrack
trackobj = natnet;
trackobj.connect;

% set up arduino/test if arduino not working
if ~debug
    try
        % First close any existing instances of the arduino
        % This doesn't seem to work - arduino can be open in the main
        % workspace but not detected here...
        try % this will error out if there isn't an arduino already connected...
            fclose(instrfindall);
        end
        try
            delete(instrfindall);
        end
            
        % now connect
        a = arduino;
        configurePin(a,'D2','DigitalOutput');
        configurePin(a,'D4','DigitalOutput');
    catch
        disp('WARNING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
        disp('ERROR connecting to arduino - running in debug mode')
        debug = true;
    end
end

% set up window sanity check
hf = figure; set(gcf,'Position', [250 500 1100 430]); ax = subplot(1,2,1);
imagesc(ax, 1);
colormap(ax,[1 0 0])
ht = text(ax, 1, 1, 'OFF', 'FontSize', 50, 'HorizontalAlignment', 'center');
subplot(1,2,2);
hl = plot(pos_lin); hold on;
hl(2) = plot(pos_lin,'r.');

% Make aware running in DEBUG mode, set arduino object to nan.
if debug
    a = nan;
    disp('RUNNING IN DEBUG MODE!!!')
end

%Get track ends
input('Put rigid body at start of the track. Hit enter when done','s');
capture_pos(trackobj);
start_pos = pos(end,:);
% start_pos = [-0.2557 0.1353 -3.6050]; % For debugging only

input('Put rigid body at end of the track. Hit enter when done','s');
capture_pos(trackobj);
end_pos = pos(end,:);
% end_pos = [-0.3754 0.2064 3.8861]; % For debugging only

% Calculate track distance along the z-axis (must set up in OptiTrack
% first! ( Assumes y is up, x-z plane is on ground! Make sure "optitrack
% streaming engine tab has Up Axis = y!!!)

% calculate angle of track for transformation to track coords
center = mean([start_pos; end_pos]);
theta = atan2(end_pos(3)-start_pos(3), end_pos(1) - start_pos(1));
track_length = pdist2(end_pos, start_pos);

% Calculate stim zone - middle of the track! Double check!!!
ttl_zone = [-1/3, 1/3]*track_length/2;

% Below is code if track is aligned with z-axis perfectly!!!
track_zdist = end_pos(3) - start_pos(3);
ttl_zzone = [start_pos(3) + track_zdist/3, start_pos(3) + track_zdist*2/3];

disp(['zone start = ' num2str(ttl_zone(1),'%0.2g')])
disp(['zone end = ' num2str(ttl_zone(2),'%0.2g')])

input('Ready to rock and roll. Hit enter when ready!','s');

% Start timer to check every SR Hz if rat is in the stim zone.
t = timer('TimerFcn', @(x,y)zone_detect(trackobj, ax, ht, ttl_zone, theta, center), ...
    'StartFcn', @(x,y)send_start(), 'StopFcn', @(x,y)send_end(), 'Period', 1/SR, ...
    'ExecutionMode', 'fixedRate', 'TasksToExecute', SR*run_time); %, ...
%     'StopFcn', @(x,y)trigger_off(a, ax, ht, pos));

t2 = timer('TimerFcn', @(x,y)minute_marker(), 'StartFcn', @(x,y)minute_marker(),...
    'Period', 60, 'ExecutionMode', 'fixedRate', 'TasksToExecute', run_time);

% Create cleanup function
cleanup = onCleanup(@()myCleanupFun(t, t2, ax, ht));

% start function!
start(t)
start(t2)

% While loop here - should be able to start or stop timer! maybe keyboard
% statement? yes!
disp('Type "stop(t); stop(t2); dbcont" to finish and save')
figure(hf); % bring figure to front
keyboard

clear a


end

%% Start minute marker - turns on on even minutes and off on odd minutes
function [] = minute_marker()
global a
global D4value

if D4value == 0
    D4value = 1;
elseif D4value == 1
    D4value = 0;
end

writeDigitalPin(a,'D4',D4value);

end

%% Start recording marker
function [] = send_start()
global a
global D4value
D4value = 1;
writeDigitalPin(a,'D4',D4value);


end

%% End recording marker - switch D4value at end!!!
function [] = send_end()
global a
global D4value
global time_opti
global time_mat
global pos_lin
global pos_opti
global trig_on
global on_minutes
global save_loc

if D4value == 1
    D4value = 0;
elseif D4value == 0
    D4value = 1;
end
writeDigitalPin(a,'D4',D4value);

% Should give decent idea of when you stopped things...
save(save_loc, 'time_opti', 'time_mat', 'pos_lin', 'pos_opti', 'trig_on', ...
    'on_minutes');

end


%% Capture live position
function [delta_pos] = capture_pos(c)
% adjust this to get delta pos from 0.25 sec prior!!!
global pos
global pos_opti
global time_opti
global time_mat

frame = c.getFrame; % get frame
time_opti = [time_opti; frame.Timestamp];
time_mat = [time_mat; clock];

% Add position to bottom of position tally
pos = [pos; ...
    frame.RigidBody(1).x, frame.RigidBody(1).y, frame.RigidBody(1).z];
pos_opti = [pos_opti; ...
    frame.RigidBody(1).x, frame.RigidBody(1).y, frame.RigidBody(1).z];

% get change in position from  0.25 seconds ago
delta_pos = pos(end,:) - pos(1,:);

% update pos to chop off most distant time point
pos = pos(2:end,:);

end

%% Detect if in zone and trigger
function [] = zone_detect(c, ax, ht, ttl_zone, theta, center)
global pos
global pos_opti
global time_opti
global time_mat
global pos_lin
global trig_on
global save_loc
global zone_sum
global SR
global D4value
global on_minutes

delta_pos = capture_pos(c); % get position
pos_curr = pos(end,:);
pos_s = cart_to_track(pos_curr, theta, center);
pos_lin = [pos_lin; pos_s];

% Turn TTL off if rat's position has not changed at all (most likely
% optitrack can't find it) OR if rat is chilling within zone for greater
% than zone_thresh seconds
zone_thresh = 3;
if all(delta_pos == 0) || zone_sum >= zone_thresh*SR %sqrt(sum(delta_pos.^2)) < 0.05 %
    trigger_off(ax, ht, pos_s)
    trig_on = [trig_on; 0];
    if (pos_s <= ttl_zone(1)) || (pos_s >= ttl_zone(2))
        zone_sum = 0; % reset time in trigger zone to 0
    end
    
else % Logic to trigger is the rat is in the appropriate zone below
%     Send D2 to 5V if in zone and currently at 0
    if (pos_s > ttl_zone(1)) && (pos_s < ttl_zone(2)) %pos_curr(3) > ttl_zone(1) && pos_curr(3) < ttl_zone(2)
        trigger_on(ax, ht, pos_s)
        trig_on = [trig_on; 1];
        zone_sum = zone_sum + 1; % Increment time tracked in trigger zone
        
%         Send D2 to 0V if outside of zone and currently at 5V
    elseif (pos_s <= ttl_zone(1)) || (pos_s >= ttl_zone(2)) %(pos_curr(3) <= ttl_zone(1)) || (pos_curr(3) >= ttl_zone(2))
        trigger_off(ax, ht, pos_s)
        trig_on = [trig_on; 0];
        zone_sum = 0; % reset time in trigger zone to 0
        
    end
    
end

on_minutes = [on_minutes; D4value];


save(save_loc, 'time_opti', 'time_mat', 'pos_lin', 'pos_opti', 'trig_on', ...
    'on_minutes');

end

%% Turn on LED/screen
function [] = trigger_on(ax, ht, pos_curr)

global D2value
global a
global pos_lin
global trig_on
global hl
D2value = 1;
% text_append = '';

if length(pos_curr) == 3
    pos_use = pos_curr(3);
else
    pos_use = pos_curr;
end

if isobject(a)
    writeDigitalPin(a,'D2',0) % OCSlite1 only seems to trigger when it detects an off->on tranisition
    writeDigitalPin(a,'D2',D2value)
end
text_append = ['-' num2str(pos_use, '%0.2g')];

colormap(ax,[0 1 0])
ht.String = ['ON' text_append];
hl(1).YData = pos_lin;
hl(2).XData = find(trig_on == 1);
hl(2).YData = pos_lin(trig_on == 1);

end

%% Turn off LED/screen
function [] = trigger_off(ax, ht, pos_curr)

global D2value
global a
global hl
global pos_lin
global trig_on
D2value = 0;
% text_append = '';

if length(pos_curr) == 3
    pos_use = pos_curr(3);
else
    pos_use = pos_curr;
end

if isobject(a)
    writeDigitalPin(a,'D2',D2value)
end
text_append = ['-' num2str(pos_use, '%0.2g')];

colormap(ax,[1 0 0])
ht.String = ['OFF' text_append];
hl(1).YData = pos_lin;
hl(2).XData = find(trig_on == 1);
hl(2).YData = pos_lin(trig_on == 1);

end

%% Convert cartesian position to track length
function [s] = cart_to_track(pos_curr, theta, center)
% s = position on track

x = pos_curr(1); y = pos_curr(2); z = pos_curr(3);
xmid = center(1); ymid = center(2); zmid = center(3);

% calculate s two different ways
s1 = (z - zmid)/sin(theta);
s2 = (x - xmid)/cos(theta);

% Make sure you aren't dividing by zero for your calculation.
cos_lims = [-pi(), -3*pi()/4; -pi()/4, pi()/4; 3*pi()/4, pi()];
sin_lims = [-3*pi()/4 -pi()/4; pi()/4 3*pi()/4];
if any(cos_lims(:,1) <= theta & theta < cos_lims(:,2))
    s = s2;
elseif any(sin_lims(:,1) <= theta & theta < sin_lims(:,2))
    s = s1;
end

end

%% Clean up function to make sure trigger gets turned off, timer stopped, global
% vars cleared if function stops for any reason!!!
function myCleanupFun(t, t2, ax, ht)

global a

    trigger_off(ax, ht, nan)
    send_end();
    clear a

    try
        fclose(instrfindall)
        delete(instrfindall)
    end
    stop(t)
    stop(t2)
%     clear global

    close(ax.Parent(1))
    disp('cleanup function ran!')
% catch
%     disp('error running cleanup function - clear all global variables manually!')
% end

end

