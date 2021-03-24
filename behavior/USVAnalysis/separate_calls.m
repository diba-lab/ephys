function [calls_sep, high_bool] = separate_calls(mean_freq, times, threshold)
% calls_sep = separate_calls(mean_freq, times, threshold)
%   Takes USV call mean frequencies and times and splits them into low vs.
%   high calls based on the designated threshold.
%
%   INPUTS:
%   mean_freq, times: output of extract_calls, arrays of times and mean
%   frequency for each call
%
%   threshold (optional): frequency cut-off to separate high from low calls
%
%   OUTPUTS:
%   calls_sep: data structure with calls_sep.low and calls_sep.high. Each
%   of these fields contains the mean_freq and times of each call type.
%
%   high_bool: a boolean matching the size of times with a 1/true value for
%   all high calls and a 0/false value for all low calls

% set threshold to 30kHZ by default
plot_thresh = false;
if nargin < 3
    threshold = 27.5;  
    
    % if user doesn't enter in threshold plot it out down below to make 
    % them check their work
    plot_thresh = true;  
end

% Check to make sure your data matches
if length(mean_freq) ~= length(times)
    error('mean_freq and times must be the same length. Try again')
end

% now divide things up and put them into a nice structure
high_bool = mean_freq > threshold;  % boolean to identify which calls are high

calls_sep.high.mean_freq = mean_freq(high_bool);
calls_sep.high.times = times(high_bool, :);
calls_sep.low.mean_freq = mean_freq(~high_bool);
calls_sep.low.times = times(~high_bool, :);

if plot_thresh
    figure;
    
    % plot histogram of call frequencies and label it
    histogram(mean_freq, 20);
    xlabel('Frequency (kHz)')
    ylabel('# Calls')
    hold on;
    
    % plot threshold line
    ht = xline(threshold, 'r--');
    
    % label it
    legend(ht, 'threshold')

end

