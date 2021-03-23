function [times, mean_freq] = extract_calls(Calls, keep_all)
% [times, frequency_mean] = extract_calls(Calls, keep_rejected)
%   Extract start/end times and mean frequency of each USV call from
%   DeepSqueak output that is accepted.
%
%   INPUTS:
%   Calls: table loaded in from DeepSqueak output .mat file
%   keep_all (optional): set to true or 1 to keep ALL calls, even those you
%   have rejected in DeepSqueak. Default = false.
%
%   OUTPUTS:
%   times: an ncalls x 2 array with the start time of each call in column 1
%   and end time in column 2
%
%   mean_freq: an ncalls x 1 array with the mean frequency of each call
%   matching the times in the times output.

if nargin < 2
    keep_all = true;
end

% first filter out all rejected calls
if keep_all
    accept_bool = Calls.('Accept');
    Calls = Calls(accept_bool, :);
end

ncalls = size(Calls, 1);  % get number of calls detected

Box = Calls.('Box');  % grab out the only real data we want in the Box column.

times = [Box(:,1), Box(:,1) + Box(:,3)];  % get start and end time of each call

mean_freq = Box(:,2) + Box(:,4)/2;

end

