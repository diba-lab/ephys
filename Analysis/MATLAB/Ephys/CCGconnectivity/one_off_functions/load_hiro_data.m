function [bz_spikes, SampleRate] = load_hiro_data(spike_data_fullpath, session_name)
% [bz_spikes, SampleRate] = load_hiro_data(spike_data_fullpath, session_name)
%   Take beautiful, nicely formatted Hiro Miyawaki dataset and 
% parse it out into nicely formatted structure compatible with lots of
% buzcode functions.

[data_dir, name, ~] = fileparts(spike_data_fullpath);
load(spike_data_fullpath, 'spikes')
if contains(name, 'wake')
    load(fullfile(data_dir, 'wake-behavior.mat'), 'behavior');
    load(fullfile(data_dir, 'wake-basics.mat'),'basics');
    SampleRate = basics.(session_name).SampleRate;
elseif contains(name, 'sleep') % this can be used later for parsing NREM v REM v other periods...
    load(fullfile(data_dir, 'sleep-behavior.mat'), 'behavior');
end

% Make data nicely formatted to work with buzcode
bz_spikes = Hiro_to_bz(spikes.(session_name), session_name);
end

