function [pred, pvals, qvals, ccgR, tR] = CCGconv(res1,res2,SampleRate,BinSize,Duration,varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

ip = inputParser;
ip.addRequired('res1', @isnumeric);
ip.addRequired('res2', @isnumeric);
ip.addRequired('SampleRate', @(a) isnumeric(a) && a > 0);
ip.addRequired('BinSize', @(a) isnumeric(a) && a > 0); % in seconds!
ip.addRequired('Duration', @(a) isnumeric(a) && a >= BinSize); % in seconds!
ip.addParameter('jscale', 5, @(a) isnumeric(a) && a > 0); % unit is ms!
ip.addParameter('njitter', 500, @(a) isnumeric(a) && a > 0 && round(a) == a);
ip.addParameter('alpha', 0.01, @(a) a > 0 && a < 1);
ip.addParameter('plot_output', 1, @(a) isnumeric(a) && a > 0 && round(a) == a);
ip.addParameter('subfig', 1, @(a) a > 0 && a <= 16);
ip.parse(res1, res2, SampleRate, BinSize, Duration, varargin{:});

jscale = ip.Results.jscale;
njitter = ip.Results.njitter;
alpha = ip.Results.alpha;
plot_output = ip.Results.plot_output;
subfig = ip.Results.subfig;

% Make spike-trains column vectors
if isrow(res1); res1 = res1'; end
if isrow(res2); res2 = res2'; end

HalfBins = round(Duration/BinSize/2);
one_ms = 0.001;

% set default values
if plot_output
    ccgj = zeros(2*HalfBins+1,njitter);
end

ccgjmax = zeros(1,njitter);
ccgjmin = zeros(1,njitter);

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
        win_size = round(jscale/1000/BinSize/2);
        [pvals, pred, qvals] = EranConv(ccgR(:,1,2), win_size);
    end
    
end

figure;
bar(tR*1000, ccgR(:,1,2),'k');
hold on;
plot(tR*1000, pred, 'b--');
xlabel('Time Lag (ms'); ylabel('Count');
end

