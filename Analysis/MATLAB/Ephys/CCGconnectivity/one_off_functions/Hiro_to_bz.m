function [spikes] = Hiro_to_bz(spikes_file, session_name)
% spikes = Hiro_to_bz(spikes_mat_file, wake_sleep, session_name)
%   This one-off function converts Hiro Miyawaki's data 
% (Miyawaki et al., 2016) in .mat format to the output format of 
% bz_GetSpikes, or at least enough to msec time-scale functions by
% K.Diba or D.English & S.McKenzie. Also spits out quality (1,2,3 = best,
% better, ok, poor pyramidal neurons, 8 = interneuron, 9 = MUA. 
% 4 and 9 are filtered out by default.
%
%   INPUTS
%   spikes: spikes file from Hiro Miyawaki data
%   session_name: e.g. 'RoySleep0' or 'KevinMaze1'. Note that wake
%       v sleep can be un-ambiguously determined from this ('Rest =
%       pre-maze during dark cycle, 'Sleep' = post-maze sleep during light
%       cycle, 'Maze' = 3 hr end of rest + 3 hour on linear track + 3 hour
%       beginning of sleep).
%
%  OUTPUTS - see bz_GetSpikes. Includes spike.times, .UID, .sessionName,
%  .shankID, and .cluID. Spike times in MILLISECONDS.

time_to_msec=1/(1000); 

spikes.sessionName = session_name;

% Filter out MUA and poor quality interneurons
UIDall = 1:length(spikes_file);
quality_all = cat(1, spikes_file.quality);
good_bool = ismember(quality_all, [1 2 3 8]); % filter out poor pyr. cells (4) and MUA (9).
spikes.UID = UIDall(good_bool);
spikes_file_filt = spikes_file(good_bool);
nneurons = length(spikes_file_filt);

% spike times
[stimes_sec{1:nneurons}] = deal(spikes_file_filt.time);
spikes.times = cellfun(@(a) a'*time_to_msec, stimes_sec, ...
    'UniformOutput', false); % make row array

% spinindices
UIDs_cell = arrayfun(@(a) ones(size(spikes.times{a}))*spikes.UID(a), ...
    1:nneurons, 'UniformOutput', false);
times_unsorted = cat(1, spikes.times{:});
[times_sorted, isort] = sort(times_unsorted); % sort
UIDs_unsorted = cat(1, UIDs_cell{:});
spikes.spindices = [times_sorted, UIDs_unsorted(isort)];

% shankID and cluID
shank_clu = cat(1, spikes_file_filt.id);
spikes.shankID = shank_clu(:,1)'; 
spikes.cluID = shank_clu(:,2)';

% quality
spikes.quality = cat(1, spikes_file_filt.quality)';

% stability
spikes.stability = cat(1, spikes_file_filt.stability)';

end

