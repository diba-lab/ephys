function [pvals, pred, qvals, ccgR, tR] = CCGconv(res1,res2,SampleRate,...
    BinSize, Duration,varargin)
% CCGconv(res1,res2, SampleRate, BinSize, Duration, varargin)
%   Calculate CCG and stats for millisecond connectivity using convolution
%   method from Stark and Abeles (2009).  See file for inputs.
%
% Written by K.Diba circa 2014, updated by N. Kinsky 2020.

ip = inputParser;
ip.addRequired('res1', @isnumeric);
ip.addRequired('res2', @isnumeric);
ip.addRequired('SampleRate', @(a) isnumeric(a) && a > 0);
ip.addRequired('BinSize', @(a) isnumeric(a) && a > 0); % in seconds!
ip.addRequired('Duration', @(a) isnumeric(a) && a >= BinSize); % in seconds!
ip.addParameter('jscale', 5, @(a) isnumeric(a) && a > 0); % unit is ms!
ip.addParameter('alpha', 0.01, @(a) a > 0 && a < 1);
ip.addParameter('plot_output', 1, @(a) isnumeric(a) && a > 0 && round(a) == a);
ip.addParameter('wintype', 'gauss', @(a) ismember(a, {'gauss', 'rect', 'triang'}));  %convolution window type
ip.addParameter('ha', 1, @(a) isempty(a) || ishandle(a));
ip.parse(res1, res2, SampleRate, BinSize, Duration, varargin{:});

jscale = ip.Results.jscale;
alpha = ip.Results.alpha;
plot_output = ip.Results.plot_output;
ha = ip.Results.ha;
wintype = ip.Results.wintype;

% Make spike-trains column vectors
if isrow(res1); res1 = res1'; end
if isrow(res2); res2 = res2'; end

% Make sure CCGs are big enough for smoothing window and make duration
% longer if not
win_size = round(jscale/1000/BinSize); % calculate window size
SDG = win_size/2;
switch wintype
    case 'gauss'
        if round(SDG) == SDG; wconv_len = 6*SDG + 1; else wconv_len = 6*SDG + 2; end
    case 'rect'
        if mod(wintype,2) == 0; wconv_len = length(wintype) + 1; else wconv_len = length(wintype); end
    case 'triang'
        if mod(wintype,2) == 0; wconv_len = 2*length(wintype) + 1; else wconv_len = 2*length(wintype) - 1; end 
end
nbins = 2*round(Duration/BinSize/2)+1;
dur_lims = Duration/2*[-1 1];
if nbins < (1.5*wconv_len)  % upsize nbins if too short
    old_dur = Duration;
    nbins_min = round(1.5*wconv_len) + 2;
    Duration = 2*nbins_min*BinSize;
    dur_lims = old_dur/2*[-1 1];
        persistent DUR_WARNING
        if ~DUR_WARNING
            warning(['Specified Duration of ' num2str(old_dur) ' seconds not large enough for convolution window.'])
            warning(['Using new Duration of ' num2str(Duration, '%0.3g') ' seconds.'])
            DUR_WARNING = true;
        end

end

HalfBins = round(Duration/BinSize/2);
tR = -HalfBins:HalfBins;
ccgR = zeros(2*HalfBins+1,2,2);

if ~isempty(res1) && ~isempty(res2)
    % NK note - rather than speed things up, this seems to just bog things
    % down... commenting out for now.
%     try
%         nn = NearestNeighbour(res1,res2,'both',BinSize*(HalfBins+1));
%     catch
%         try
%             nn = nearestneighbour(res1',res2','Radius',BinSize*(HalfBins+1));
%         catch ME
%             if strcmp(ME.identifier, 'MATLAB:array:SizeLimitExceeded')
%                 warning('Super large spike trains - skipping CCG_jitter time-saving step');
%                 nn = 1;
%             else
%                 error('Error in CCG_jitter>nearest_neighbor')
%             end
%             
%         end
%     end
%     
%     if isempty(nn)
%         % try to save some time in case no overlap
%         warning('two spike trains do not overlap by BinSize*(HalfBins+1)');
%         pvals = nan;
%         pred = nan;
%         qvals = nan;
%     else
        
        [ccgR, tR] = CCG([res1;res2],[ones(size(res1));2*ones(size(res2))], ...
            'binSize', BinSize, 'duration', Duration, 'Fs', 1/SampleRate,...
            'norm', 'counts');
        
        [pvals, pred, qvals] = EranConv(ccgR(:,1,2), win_size, wintype);
%     end
    
end

if plot_output
    figure(plot_output)
    
    % select appropriate axes to plot into
    if isempty(ha)
        subplot(1,1,1);
    else
        axes(ha);
        
    end
    bar(tR*1000, ccgR(:,1,2),'k');
    hold on;
    try
        hpred = plot(tR*1000, pred, 'b--');
%         legend(hpred, 'Conv');
    catch ME
        if strcmp(ME.identifier,'MATLAB:UndefinedFunction')
            warning('No spikes in CCG! Skipping!')
        end
    end
    xlim(dur_lims*1000);  % Make x-axis the input size specfied even if you used a larger smoothing window.
    xlabel('Time Lag (ms)'); ylabel('Count');

end

end

