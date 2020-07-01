function [ExcPairs,InhPairs,GapPairs,Rzero] = EranConv_group(spiket,spikeind,Cells,...
    SampleRate,jscale,alpha,shank,wintype)
% [ExcPairs,InhPairs,GapPairs] = EranConv_group(spiket,spikeind,Cells,...
%                                SampleRate,jscale,alpha,shank,wintype)
%
% This function calculates pairs of neurons with millisecond time-scale
% synchrony and spits out excitatory and inhibitory connections 
% (peaks or troughs in CCG from 0.5 to 3.0ms) and "gap" connections
% (peak in CCG < 0.5ms).
% 
%
% INPUTS
% spiket = spike times in SECONDS.
% spikeind = unique id for each spike time (i.e. the corresponding cluster)
% Cells = the cells to search through (can exclude some of the spikeind group)
% using Eran Stark's convolution method to test for connections between
% neuron pairs. 1:ncells array
% shank = shank for each neuron in Cells.
%
% OUTPUTS
% cell1 ID
% cell2 ID
% cell1 shank;cluster
% cell2 shank;cluster
% pvalue of connection.
% shank is needed in case neurons are on the same shank

if nargin < 8
    wintype = 'gauss';
end

nCells = length(Cells);

InhPairs = [];
ExcPairs = [];
GapPairs = [];
Rzero = [];

one_ms = 0.001;  %one_ms = SampleRate/1000;
BinSize = 0.001;
Duration = 0.05;
 
% alpha_base = .1;
if alpha == .01
    alpha_base = .05; % this is needed for the second bin in inhibitory pairs, to make sure at least two bordering bins meet some criterion.
elseif alpha == .05
    alpha_base = .1;
else
    alpha_base = .05; % default
end

if jscale < 2*ceil(BinSize/one_ms)
    beta = 2;
else
    beta = jscale/(jscale-BinSize/one_ms);
end
        
% tR = -HalfBins:HalfBins;

% make column vectors if row vectors entered
if isrow(spikeind); spikeind = spikeind'; end
if isrow(spiket); spiket = spiket'; end

plot_output = 0;

% ii=0;jj=0;kk=0;
for cell_i=1:nCells-1
    %     disp(['evaluating all pairs for cell #' num2str(cell_i) '/' num2str(nCells) ' ...'])
    for cell_j=cell_i+1:nCells
        shank_i = shank(cell_i);
        shank_j = shank(cell_j);
%         find_i=find(spikeind==Cells(cell_i));
%         find_j=find(spikeind==Cells(cell_j));
%         shank_i = shank(find_i(1));
%         shank_j = shank(find_j(1));
        %         [GSPE,GSPI]=CCG_jitter(spiket,spikeind,clu1,clu2,BinSize,HalfBins,jscale,njitter,alpha,plot_output);
        %         % to compare with jitter
        i_bool = spikeind == Cells(cell_i);
        j_bool = spikeind == Cells(cell_j);
        T_ij = [spiket(i_bool);spiket(j_bool)];
        G_ij = [ones(sum(i_bool),1);2*ones(sum(j_bool),1)];
        
        [ccg_ij,tR] = CCG(T_ij, G_ij, 'binSize', BinSize, 'duration', ...
            Duration, 'Fs', 1/SampleRate, 'norm', 'counts');
        ccg_ij = squeeze(ccg_ij(:,1,2)); 
        tR = tR*1000; % convert time to ms.
        
        if shank_i==shank_j  %  this is to prevent empty bins from same shank from influencing results
            offzero_bins = find(tR~=0);
            ccg_ij = ccg_ij(offzero_bins);
            tR = tR(offzero_bins);
        end
        
        
        if isempty(ccg_ij)
            keyboard
        end
        [pvals,smoothccg,qvals] = EranConv(ccg_ij,jscale,wintype);

        [peak, peak_ii] = min(pvals);
        [trough, trough_ii] = min(qvals);
        
        MonoWindow1=find((tR>=0.5)&(tR<=3.5));     % Mono Window 1ms ~ 5ms
        MonoWindow2=find((tR>=-3.5)&(tR<=-0.5));
        MonoWindow3=find((tR>-0.5)&(tR<0.5));
        
        maxccg = max(smoothccg);
        minccg = min(smoothccg);
        
        avg_ccgcount = 2.5;
        %         if sum(ccg_ij(HalfBins-10:HalfBins+10))>avg_ccgcount*21;
        %             %%%%%%%%%%% Excitatory
        %             if     any(pvals(MonoWindow1)<alpha)
        %                 ExcPairs = [ExcPairs [Cells([cell_i cell_j]) ; 1/(eps+min(pvals(MonoWindow1)))]];
        %             elseif any(pvals(MonoWindow2)<alpha)
        %                 ExcPairs = [ExcPairs [Cells([cell_j cell_i]) ; 1/(eps+min(pvals(MonoWindow2)))]];
        %             elseif any(pvals(MonoWindow3)<alpha)
        %                 GapPairs = [GapPairs [Cells([cell_i cell_j]) ; 1/(eps+min(pvals(MonoWindow3)))]];
        %             end
        %         end
        %         if sum(ccg_ij(HalfBins-10:HalfBins+10))>avg_ccgcount*21;
        %             %%%%%%%%%%% Inhibitory
        %             if     any(qvals(MonoWindow1)<alpha)
        %                 InhPairs = [InhPairs [Cells([cell_i cell_j]) ; 1/(eps+min(qvals(MonoWindow1)))]];
        %             elseif any(qvals(MonoWindow2)<alpha)
        %                 InhPairs = [InhPairs [Cells([cell_j cell_i]) ; 1/(eps+min(qvals(MonoWindow2)))]];
        %             end
        %         end
        
        % Get ms synchrony value at center time bin.
        if sum(tR == 0) == 1
            Rzero = [Rzero; [Cells([cell_i cell_j]) ccg_ij(tR == 0)/smoothccg(tR == 0)]];
        elseif ~any(tR == 0)
            Rzero = [Rzero; [Cells([cell_i cell_j]) nan]];
        end
        global_bool = tR <= 12 & tR >= -12; % find all valid bins within 12ms of 0
        if sum(ccg_ij(global_bool))>avg_ccgcount*sum(global_bool)  % only proceed if > 2.5 spikes/bin on average
            %%%%%%%%%%% Excitatory
            if ismember(peak_ii, MonoWindow1) && peak<alpha
%             if any(pvals(MonoWindow1)<alpha)
                [~,mi] = min(pvals(MonoWindow1));
%                 p_score = (ccg_ij(MonoWindow1(mi))-smoothccg(MonoWindow1(mi)))/(maxccg-minccg)/.5;
                p_score = (ccg_ij(MonoWindow1(mi))-smoothccg(MonoWindow1(mi)))/min([sum(i_bool),sum(j_bool)])*beta;
                ExcPairs = [ExcPairs; [Cells([cell_i cell_j]) p_score]];
            end
            if ismember(peak_ii, MonoWindow2) && peak<alpha
%             if any(pvals(MonoWindow2)<alpha)
                [~,mi] = min(pvals(MonoWindow2));
                p_score = (ccg_ij(MonoWindow2(mi))-smoothccg(MonoWindow2(mi)))/min([sum(i_bool),sum(j_bool)])*beta;
                ExcPairs = [ExcPairs; [Cells([cell_j cell_i]) p_score]];
            end
            %%%%%%%%%%%%% Gap Junction
            if ismember(peak_ii, MonoWindow3) && peak<alpha
%             if any(pvals(MonoWindow3)<alpha)
                [~,mi] = min(pvals(MonoWindow3));
                p_score = (ccg_ij(MonoWindow3(mi))-smoothccg(MonoWindow3(mi)))/min([sum(i_bool),sum(j_bool)])*beta;
                GapPairs = [GapPairs; [Cells([cell_i cell_j]) p_score]];
            end
            %         end
            %         if sum(ccg_ij(HalfBins-10:HalfBins+10))>avg_ccgcount*21;
            %%%%%%%%%%% Inhibitory
            %             if     any((qvals(MonoWindow1)<alpha))
            %                 ii_a = find(qvals(MonoWindow1)<alpha);
            %                 if qvals(MonoWindow1(ii_a)-1)<alpha|qvals(MonoWindow1(ii_a)+1)<alpha
            %             if     any((qvals(MonoWindow1)<alpha)&(qvals(MonoWindow1+1)<alpha))
            if  sum(qvals(MonoWindow1)<alpha_base)>1 && any(qvals(MonoWindow1)<alpha)  % at least one signif window at alpha and 2 at alpha_base
                ii_a = find(qvals < alpha)';  % where are all the signif bin?
                pair_flag = 0;
                for jj = ii_a   % search to see if there is one with a neighboring signficant indice (at alpha_base)
                    if ismember(jj,MonoWindow1) && ((ismember(jj+1, MonoWindow1) && (qvals(jj+1)<alpha_base))|(ismember(jj-1,MonoWindow1)&qvals(jj-1)<alpha_base))
                        pair_flag = 1;
                    end
                end
                if pair_flag == 1 % if these requirements are met, then consider it a putative pair.
                    [~,mi] = min(qvals(MonoWindow1));
                    
                    p_score = beta*(smoothccg(MonoWindow1(mi))-ccg_ij(MonoWindow1(mi)))/min([sum(i_bool),sum(j_bool)]);
                    InhPairs = [InhPairs; [Cells([cell_i cell_j]) p_score]];
                    %             elseif any((qvals(MonoWindow2)<alpha))
                    %             elseif
                    %             any((qvals(MonoWindow2)<alpha)&(qvals(MonoWindow2-1)<alpha))
                end
            end
            if sum(qvals(MonoWindow2)<alpha_base)>1 && any(qvals(MonoWindow2)<alpha)
                ii_a = find(qvals < alpha)'; % find all significant indices
                pair_flag = 0;
                for jj = ii_a   % search to see if there is one with a neighboring signficant indice (at alpha_base)
%                     if ismember(jj,MonoWindow2)&((ismember(jj+1, MonoWindow2)&(qvals(jj + 1)<alpha_base))|(ismember(jj-1,MonoWindow2)&qvals(jj-1)<alpha_base))
                    if ismember(jj,MonoWindow2) && ((ismember(jj+1, MonoWindow2) && (qvals(jj + 1)<alpha_base))|(ismember(jj-1,MonoWindow2)&qvals(jj-1)<alpha_base))
                        pair_flag = 1;
                    end
                end
                if pair_flag == 1
                    [~,mi] = min(qvals(MonoWindow2));
                    p_score = (smoothccg(MonoWindow2(mi))-ccg_ij(MonoWindow2(mi)))/min([sum(i_bool),sum(j_bool)]);
                    InhPairs = [InhPairs; [Cells([cell_j cell_i]) p_score]];
                end
            end
        end
    end
end
end
