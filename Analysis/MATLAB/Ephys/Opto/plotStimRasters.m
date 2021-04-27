function ha = plotStimRasters(PEtimes, stim_times, limits, ha, bin_size)
% plotStimRasters(PEtimes, stim_times, limits, ha, bin_size)
%   Plots rasters around time of stimulation. PEtimes = peri-event spike
%   times (nevents length cell). stim_times = length 2 array with on and
%   off times of stimulation. limits = time limits for plotting. ha = axes
%   to plot into (empty = new figure). bin_size = time in seconds for
%   calculating PETH and plotting (empty = don't calculate or plot).

if nargin < 5
    bin_size = [];
    if nargin < 4
        ha = '';
        if nargin < 3
            limits = [-1 2];
        end
    end
end



if isempty(ha)
    figure; ha = gca;
    
end

nevents = length(PEtimes);
for j = 1:nevents
    if ~isempty(PEtimes{j})
        plot(PEtimes{j}, -j*ones(size(PEtimes{j})), 'b.'); 
        hold on; 
    end
end
hp = patch([stim_times(1) stim_times(1) stim_times(2) stim_times(2) stim_times(1)], ...
    [-nevents 0 0 -nevents -nevents], 'g');
hp.FaceAlpha = 0.2;
ylabel('Trial'); xlabel('Time from Stim (s)')
set(gca, 'xlim', limits);
set(gca,'ylim',[-nevents, 0], 'YTick',[-nevents 0],'YTickLabels', ...
    arrayfun(@num2str, abs([-nevents 0]),'UniformOutput', false))

%% Now plot PETH averages
PEhisto = [];
if ~isempty(bin_size)
    edges = limits(1):bin_size:limits(2);
    nbins = length(edges) - 1;
    PEhisto = nan(nevents, nbins);
    for j = 1:nevents
       PEhisto(j,:) = histcounts(PEtimes{j}, edges); 
    end
    centers = mean(diff(edges))/2 + edges(1:end-1);
    
    % Now plot
    yyaxis right
    hold on; plot(centers, mean(PEhisto,1)/bin_size)
    ylabel('Mean MUA rate (Hz)')
    
end

end

