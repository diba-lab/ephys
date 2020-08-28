function [PEtimes] = generate_PErasters(spike_times, event_times, bin_size, limits)
% PEtimes = generate_PErasters(spike_times, event_times, bin_size, limits)
%   Generate a peri-event raster and histogram. Spike_times = array of spike times (sec).
%   Event_times = array of event times (sec). bin_size in seconds too
%   (default = 0.1). limits = time before/after to use. default = 1 sec.
%
%   PEtimes: spike times for each event +/- event center.
if nargin < 4
    limits = [-1 1];
    if nargin < 3
        bin_size = 0.1;
    end
end

edges = limits(1):bin_size:limits(2);
nbins = length(edges) - 1;

nevents = length(event_times);

%% ID spike times for each event +  histogram
PEtimes = cell(nevents,1);
for j = 1:nevents
    PEtimes{j} = spike_times(spike_times < event_times(j) + limits(2) & ...
        spike_times > event_times(j) + limits(1)) - event_times(j);
end




end

