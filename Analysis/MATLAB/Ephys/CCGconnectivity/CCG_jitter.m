%  function [GSPExc,GSPInh,pvalE,pvalI,ccgR,tR,LSPExc,LSPInh,JBSIE,JBSII]= ...
%  CCG_jitter(res1,res2,SampleRate,BinSize,Duration,varargin)
%
%  INPUTS:
%  res1 res2 : the spike times for the two cells, in SECONDS.
%  SampleRate: Acquisition frame rate.
%  BinSize   : size of bin in SECONDS. See CCG.m.
%  Duration  : total width of cross-correlogram in SECONDS. e.g. 
%              0.02 would give a plot with xlimits = [-0.01, 0.01].
%              See CCG.m.
%  NAME-VALUE PARAMETERS:       
%  jscale            : jittering scale, unit is 'ms' (default = 5ms);
%  njitter           : # of times jittering
%  alpha             : significance level for plotting purposes
%  ---------------------------------------------------
%  ccgR   : ccg of real data   <-- [ccg,t]=CCG(...);
%  tR     : t of real data
%  GSPExc : Global Significant Period of Mono Excitation.
%  GSPInh : Global Significant Period of Mono Inhibition.
%  LSPExc : Local Significant Period of Mono Excitation.
%  LSPInh : Local Significant Period of Mono Inhibition.
%  ---------------------------------------------------
% JBSIE and JBSII are the jitter-based synchrony indices based on the measure from Agmon (2012) Neural Syst Circ 2:5. 
%  Example  :  [GSPExc,GSPInh,pvalE,pvalI,ccgR,tR,LSPExc,LSPInh,JBSIE,JBSII] = ...
%    CCG_jitter(res1,res2,20000,20,25,'jscale',5,'njitter',500,'alpha',0.01);
%             --- binsize is 1ms (20khz), jitter time scale is 5ms, 
%                 500 times jittering, p<0.01
%
%  Coded by  Shigeyoshi Fujisawa, modified by K Diba
%  based on Asohan Amarasimghan's resampling methods
%  modified by N Kinsky (2020).

function [GSPExc,GSPInh,pvalE,pvalI,ccgR,tR,LSPExc,LSPInh,JBSIE,JBSII]=...
    CCG_jitter(res1,res2,SampleRate,BinSize,Duration,varargin)

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
ip.addParameter('subplot_size', [4,4], @(a) length(a) == 2);
ip.parse(res1, res2, SampleRate, BinSize, Duration, varargin{:});

jscale = ip.Results.jscale;
njitter = ip.Results.njitter;
alpha = ip.Results.alpha;
plot_output = ip.Results.plot_output;
subfig = ip.Results.subfig;
subplot_size = ip.Results.subplot_size;

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
%                 warning('Super large spike trains - skipping CCG_jitter time-saving step');
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
        
        %%%%%%  CCG for jittering data
        for ii=1:njitter
%             This is probably ok but could end up with jittered spike
%             times that don't conform to SampleRate
%             res2_jitter = res2 + 2*(one_ms*jscale)*rand(size(res2))-1*one_ms*jscale;
            res2_jitter = round((res2 + 2*(one_ms*jscale)*rand(size(res2))-1*one_ms*jscale)*SampleRate)/SampleRate;
            % in ideal, we would find all instances where two spikes occur
            % less than 1 ms apart, and remove those from the analysis.  

            [ccg] = CCG([res1;res2_jitter],[ones(size(res1));2*ones(size(res2))], ...
                'binSize', BinSize, 'duration', Duration, 'Fs', 1/SampleRate, ...
                'norm', 'counts');
            ccgj(:,ii)=ccg(:,1,2);
            ccgjmax(ii)=max(ccg(:,1,2));
            ccgjmin(ii)=min(ccg(:,1,2));
        end
    end
end

%%%%%%  Compute the pointwise line
signifpoint = floor(njitter*(alpha/2));

%%%%%%  Compute the global line
sortgbDescend   = sort(ccgjmax,'descend');
sortgbAscend    = sort(ccgjmin,'ascend');
ccgjgbMax  = sortgbDescend(signifpoint)*ones(1,2*HalfBins+1);
ccgjgbMin  = sortgbAscend(signifpoint)*ones(1,2*HalfBins+1);


%% Presentation

for ii=1:2*HalfBins+1
    sortjitterDescend  = sort(ccgj(ii,:),'descend');
    sortjitterAscend   = sort(ccgj(ii,:),'ascend');
    ccgjptMax(ii) = sortjitterDescend(signifpoint);
    ccgjptMin(ii) = sortjitterAscend(signifpoint);
end
ccgjm  = mean(ccgj,2);

if plot_output
    figure(plot_output)
    
    % If new figure, just do one plot
    if isempty(get(figure(plot_output),'Children'))
        subplot(1,1,subfig);
    else % If pre-existing figure, plot into 4x4 array
        subplot(subplot_size(1), subplot_size(2), subfig)
    end
    tRms = tR*1000;
    bar(tRms,ccgR(:,1,2),'k')
    line(tRms,ccgjm,'linestyle','--','color','b')
    line(tRms,ccgjptMax,'linestyle','--','color','r')
    line(tRms,ccgjgbMax,'linestyle','--','color','g')
    line(tRms,ccgjptMin,'linestyle','--','color','r')
    line(tRms,ccgjgbMin,'linestyle','--','color','g')
    xlabel('Time Lag (ms)');
    ylabel('Count');
    set(gca,'XLim',[min(tRms),max(tRms)])
end

%% Significant Period

GSPExc = zeros(size(tR));  % Global Significant Period of Mono Excitation
GSPInh = zeros(size(tR));  % Global Significant Period of Mono Inhibition

LSPExc = zeros(size(tR));  % Local Significant Period of Mono Excitation
LSPInh = zeros(size(tR));  % Local Significant Period of Mono Inhibition

pvalE = ones(size(tR));
pvalI = ones(size(tR));
    
min_ccgcount = 1*(2*HalfBins+1);
mincount = 6;
if sum(ccgR(:,1,2))>min_ccgcount

    Exc_ind = (ccgR(:,1,2)>ccgjgbMax')&(ccgR(:,1,2)>=mincount);
    Inh_ind = (ccgR(:,1,2)<ccgjgbMin'); 
    
    GSPExc(Exc_ind) = 1;
    GSPInh(Inh_ind) = 1;

    Exc_ind = (ccgR(:,1,2)>ccgjptMax')&(ccgR(:,1,2)>=mincount); 
    Inh_ind = (ccgR(:,1,2)<ccgjptMin'); 

    LSPExc(Exc_ind) = 1;
    LSPInh(Inh_ind) = 1;

    if jscale < 2*ceil(BinSize/one_ms)
        beta = 2;
    else
        beta = jscale/(jscale-ceil(BinSize/one_ms));
    end

    JBSIE = beta*(ccgR(:,1,2)-ccgjm)/min([length(res1),length(res2)]);
    JBSII = -JBSIE;
        
    for ii=1:size(tR,1)
        pvalE(ii) = sum(ccgjmax > ccgR(ii,1,2))/njitter;
        pvalI(ii) = sum(ccgjmin < ccgR(ii,1,2))/njitter; 
    end

end
%%
end

