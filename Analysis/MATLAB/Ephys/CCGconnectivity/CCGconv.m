function [pvals, pred, qvals, ccgR, tR] = CCGconv(res1,res2,SampleRate,...
    BinSize,Duration,varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

ip = inputParser;
ip.addRequired('res1', @isnumeric);
ip.addRequired('res2', @isnumeric);
ip.addRequired('SampleRate', @(a) isnumeric(a) && a > 0);
ip.addRequired('BinSize', @(a) isnumeric(a) && a > 0); % in seconds!
ip.addRequired('Duration', @(a) isnumeric(a) && a >= BinSize); % in seconds!
ip.addParameter('jscale', 5, @(a) isnumeric(a) && a > 0); % unit is ms!
ip.addParameter('alpha', 0.01, @(a) a > 0 && a < 1);
ip.addParameter('plot_output', 1, @(a) isnumeric(a) && a > 0 && round(a) == a);
ip.addParameter('ha', 1, @(a) isempty(a) || ishandle(a));
ip.parse(res1, res2, SampleRate, BinSize, Duration, varargin{:});

jscale = ip.Results.jscale;
alpha = ip.Results.alpha;
plot_output = ip.Results.plot_output;
ha = ip.Results.subfig;

% Make spike-trains column vectors
if isrow(res1); res1 = res1'; end
if isrow(res2); res2 = res2'; end

% Make sure CCGs are big enough for smoothing window and make duration
% longer if not
win_size = round(jscale/1000/BinSize); % calculate window size
SDG = win_size/2;
if round(SDG) == SDG; wconv_len = 6*SDG + 1; else wconv_len = 6*SDG + 2; end
nbins = 2*round(Duration/BinSize/2)+1;
if nbins < (1.5*wconv_len)  % upsize nbins if too short
    old_dur = Duration;
    nbins_min = round(1.5*wconv_len) + 2;
    Duration = 2*nbins_min*BinSize;
    disp(['Specified Duration of ' num2str(old_dur) ' seconds not large enough for convolution window.'])
    disp(['Using new Duration of ' num2str(Duration, '%0.3g') ' seconds.'])
end

HalfBins = round(Duration/BinSize/2);
tR = -HalfBins:HalfBins;
ccgR = zeros(2*HalfBins+1,2,2);

if ~isempty(res1) && ~isempty(res2)
    try
        nn = NearestNeighbour(res1,res2,'both',BinSize*(HalfBins+1));
    catch
        try
            nn = nearestneighbour(res1',res2','Radius',BinSize*(HalfBins+1));
        catch ME
            if strcmp(ME.identifier, 'MATLAB:array:SizeLimitExceeded')
                warning('Super large spike trains - skipping CCG_jitter time-saving step');
                nn = 1;
            else
                error('Error in CCG_jitter>nearest_neighbor')
            end
            
        end
    end
    
    if isempty(nn)
        % try to save some time in case no overlap
        warning('two spike trains do not overlap by BinSize*(HalfBins+1)');
    else
        
        [ccgR, tR] = CCG([res1;res2],[ones(size(res1));2*ones(size(res2))], ...
            'binSize', BinSize, 'duration', Duration, 'Fs', 1/SampleRate,...
            'norm', 'counts');
        
        [pvals, pred, qvals] = EranConv(ccgR(:,1,2), win_size);
    end
    
end

if plot_output
    figure(plot_out)
    
    % select appropriate axes to plot into
    if isempty(ha)
        subplot(1,1,1);
    else
        axes(ha);
    end
    bar(tR*1000, ccgR(:,1,2),'k');
    hold on;
    hpred = plot(tR*1000, pred, 'b--');
    xlabel('Time Lag (ms'); ylabel('Count');
    legend(hpred, 'Conv');
end

end

