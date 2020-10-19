function [] = OE_TTL_to_NeuroSuite(event_dir, outfilename)
% OE_TTL_to_NeuroSuite(event_dir)
%
% Makes Neurosuite compatible .evt file for displaying TTL pulses recorded 
% in OpenEphys. Will save timestamps and TTL channel for each event (4 =
% TTL 4 triggered, -4 = TTL 4 off).
%
%   NOTE: this requires having the "readNPY" and "readNPYHeader" 
%   functions from the npy-matlab repository: 
%       https://github.com/kwikteam/npy-matlab
%
% Input: event_dir is the directory where the timestamps.npy and 
%        channel_states.npy files live
%
%       outfilename (optional): default = 'TTLevents.aaa.evt'

if nargin < 2
    outfilename = 'TTLevents.aaa.evt'
end
savefile_full = fullfile(event_dir, outfilename);

% pre-allocate
timestamps = [];
channel_states = [];

%% read in timestamps and channel states
timestamps = readNPY(fullfile(event_dir, 'timestamps.npy'));
try
    channel_states = readNPY(fullfile(event_dir, 'channel_states.npy'));
catch
    disp('No channel_states.npy file found - saving timestamps only')
end

%% Prompt user to get start time and Sample Rate in sync_messages.txt file
% In future I can write code to get this working via direct import...

disp('Navigate to sync_messages.txt file (should be 3 folders up from event_dir')
start_time = input('Enter in "start time" here: ');
SR = input('Enter in sample rate here: ');


%% Save it!
MakeEvtFile(timestamps-start_time, savefile_full, channel_states, SR, 1);


end

