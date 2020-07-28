function [ha] = plotCCG(tR, CCG, varargin)
% ha = plotCCG(tR, CCG, varargin)
%   Plots CCGs. Parameter inputs can be used to easily add on convolution
%   lines, global/pointwise jitter limits, and bins with significant
%   excitatory or inhibitory connections. Will plot into a new figure
%   unless handle axes are specified with 'ha' parameter.

ip = inputParser;
ip.addRequired('tR', @isnumeric);
ip.addRequired('CCG', @(a) length(squeeze(a)) == length(tR));
ip.addParameter('ha', [], @(a) isempty(a) || ishandle(a));
ip.addParameter('global_jitter_lims', nan, @(a) isnan(a) || length(a) == 2);
ip.addParameter('local_jitter_lims', nan, @(a) isnan(a) || size(a,1) == 2 && ...
    (size(a,2) == length(tR)));
ip.addParameter('jitter_mean', nan, @(a) isnan(a) || length(a) == length(tR));
ip.addParameter('conv_pred', nan, @(a) isnan(a) || length(a) == length(tR));
ip.parse(tR, CCG, varargin{:});
ha = ip.Results.ha;
global_lims = ip.Results.global_jitter_lims;
local_lims = ip.Results.local_jitter_lims;
jitter_mean = ip.Results.jitter_mean;
conv_pred = ip.Results.conv_pred;

CCG = squeeze(CCG);
tRms = tR*1000;

%% Set up plots
if isempty(ha)
    figure; 
    ha = subplot(1,1,1);
end

%% Plot
bar(ha, tRms, CCG, 'k')
xlabel(ha, 'Time Lag (ms)');
ylabel(ha, 'Count');
set(ha,'XLim',[min(tRms),max(tRms)])

% Now plot additional stuff if entered
if ~isnan(jitter_mean)
    line(ha, tRms, jitter_mean, 'linestyle', '--', 'color', 'b')
end

if ~isnan(global_lims)
    line(ha, tRms, global_lims(1), 'linestyle', '--', 'color', 'g')
    line(ha, tRms, global_lims(2), 'linestyle', '--', 'color', 'g')
end

if ~isnan(local_lims)
    line(ha, tRms, local_lims(1,:), 'linestyle', '--', 'color', 'r')
    line(ha, tRms, local_lims(2,:), 'linestyle', '--', 'color', 'r')
end

if ~isnan(conv_pred)
    plot(ha, tRms, conv_pred, 'b--')
end
    

end

