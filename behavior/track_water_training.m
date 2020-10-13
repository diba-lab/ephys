function [water_out, time_out] = track_water_training(capture_file, water_in, time_in)
% track_water_training(capture_file, water_in, time_in)
%  Track water training progress in real time. water_in and time_in are
%  optional inputs - use only if you forget to start at the beginning.

global water_delivs
global timestamps
global hl

if nargin == 1
   water_delivs = []; timestamps = []; 
else
    water_delivs = water_in;
    timestamps = time_in;
end
figure; ha = gca;

SR = 1; % in Hz
run_time = 3*60*60; % 3 hrs...

t = timer('TimerFcn', @(x,y)plot_licks_realtime(capture_file,...
    ha), 'StartFcn', @(x,y)plot_licks_realtime(capture_file, ...
    ha), 'StopFcn', @(x,y)plot_licks_realtime(capture_file,...
    ha), 'Period', 1/SR, 'ExecutionMode', 'fixedRate', 'TasksToExecute', run_time);

xlabel( 'Time(s)');
ylabel('Water Deliveries');

start(t);

keyboard
disp('Type "stop(t); dbcont" to finish')

cleanup = onCleanup(@()myCleanupFun(t));

end


function plot_licks_realtime(capture_file, ha)
% [water_out, time_out] = plot_licks(capture_file, water_in, time_in, ha)
%
% Plot licks versus time during water training

global water_delivs
global timestamps

data = importdata(capture_file);
water_delivs = [water_delivs, sum(data == 1) + sum(data ==3)];
timestamps = [timestamps, now];
plot(ha, (timestamps - timestamps(1))*24*60*60, water_delivs,'b-');
xlabel( 'Time(s)');
ylabel('Water Deliveries');
drawnow

end

function myCleanupFun(t)
clear global
stop(t)

end
