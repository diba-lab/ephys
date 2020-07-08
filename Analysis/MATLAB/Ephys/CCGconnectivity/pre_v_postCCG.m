function [] = pre_v_postCCG(spike_data_fullpath, session_name, varargin)
% pre_v_postCCG(spike_data_path, session_name)
%   Identify ms connectivity in ANY of the PRE-rest (3hr) , MAZE (3hr) or
%   POST-sleep (3hr) sessions and plot CCGs with stats and stuff
%   side-by-side.

ip = inputParser;
ip.addRequired('spike_data_fullpath', @isfile);
ip.addRequired('session_name', @ischar);
ip.addParameter('alpha', 0.05, @(a) a > 0 && a < 0.25);
ip.addParameter('jscale', 5, @(a) a > 0 && a < 10);
ip.addParameter('debug', false, @islogical);
ip.addParameter('conn_type', 'ExcPairs', @(a) ismember(a, {'ExcPairs', 'InhPairs', 'GapPairs'}));
ip.addParameter('wintype', 'gauss', @(a) ismember(a, {'gauss', 'rect', 'triang'})); % convolution window type
ip.addParameter('plot_jitter', false, @islogical); 
ip.addParameter('plot_top_bot', true, @islogical); % only plot the 5 most/least significant pairs...false = plot ALL pairs.
ip.addParameter('save_plots', true, @islogical); % save all the plots you make 
ip.parse(spike_data_fullpath, session_name, varargin{:});
alpha = ip.Results.alpha;
jscale = ip.Results.jscale;
debug = ip.Results.debug;
wintype = ip.Results.wintype;
conn_type = ip.Results.conn_type;
plot_jitter = ip.Results.plot_jitter;
plot_top_bot = ip.Results.plot_top_bot;
save_plots = ip.Results.save_plots;

epoch_names = {'Pre', 'Maze', 'Post'};
%% Step 0: load spike and behavioral data, parse into pre, track, and post session

[data_dir, name, ~] = fileparts(spike_data_fullpath);
if ~debug
load(spike_data_fullpath, 'spikes')
if contains(name, 'wake')
    load(fullfile(data_dir, 'wake-behavior.mat'), 'behavior');
    load(fullfile(data_dir, 'wake-basics.mat'),'basics');
    SampleRate = basics.(session_name).SampleRate;
    epochs = {'pre', 'maze', 'post'};
elseif contains(name, 'sleep') % this can be used later for parsing NREM v REM v other periods...
    load(fullfile(data_dir, 'sleep-behavior.mat'), 'behavior');
end

% Make data nicely formatted to work with buzcode
bz_spikes = Hiro_to_bz(spikes.(session_name), session_name);

% Pull out PRE, MAZE, and POST time limits
if contains(name, 'wake')
    nepochs = 3;
    time_list = behavior.(session_name).time/1000; % convert time list to milliseconds
end

nneurons = length(spikes.(session_name));
for j = 1:nepochs
    epoch_bool = bz_spikes.spindices(:,1) >= time_list(j,1) ...
        & bz_spikes.spindices(:,1) <= time_list(j,2); % ID spike times in each epoch
    parse_spikes(j).spindices = bz_spikes.spindices(epoch_bool,:); % parse spikes by epoch into this variable
end

%% Step 1: Run EranConv_group on each session and ID ms connectivity in each session
alpha_orig = alpha; jscale_orig = jscale;
try
    load(fullfile(data_dir,[session_name '_jscale' num2str(jscale) '_alpha' ...
        num2str(round(alpha*100)) '_pairs']), 'pairs', 'jscale', 'alpha')
    if alpha_orig ~= alpha || jscale_orig ~= jscale
        disp('input jscale and/or alpha values differ from inputs. Re-running Eran Conv')
        error('Re-run EranConv analysis with specified jscale and alpha')
    end
catch
    for j = 1:nepochs
        % This next line of code seems silly, but I'm leaving it in
        % You can replace bz_spike.UID with any cell numbers to only plot
        % through those. Might be handy in the future!
        cell_inds = arrayfun(@(a) find(bz_spikes.UID == a), bz_spikes.UID);
        disp(['Running EranConv_group for ' session_name ' ' epoch_names{j} ' epoch'])
        [ExcPairs, InhPairs, GapPairs, RZero] = ...
            EranConv_group(parse_spikes(j).spindices(:,1)/1000, parse_spikes(j).spindices(:,2), ...
            bz_spikes.UID(cell_inds), SampleRate, jscale, alpha, bz_spikes.shankID(cell_inds), ...
            wintype);
        pairs(j).ExcPairs = ExcPairs;
        pairs(j).InhPairs = InhPairs;
        pairs(j).GapPairs = GapPairs;
        pairs(j).RZero = RZero;
        pairs(j).jscale = jscale;
    end
    save(fullfile(data_dir,[session_name '_jscale' num2str(jscale) '_alpha' ...
        num2str(round(alpha*100)) '_pairs']), 'pairs', 'jscale', 'alpha')
end

elseif debug  % use this to cut down on time while debugging...
    if isempty(getenv('computername'))
        load('/data/Working/Other Peoples Data/HiroData/wake_new/pre_v_postCCG_debug_data.mat',...
            'bz_spikes', 'parse_spikes', 'pairs', 'SampleRate', 'wintype');
    elseif strcmp(getenv('computername'),'NATLAPTOP')
       load('C:\Users\Nat\Documents\UM\Working\HiroData\wake_new\pre_v_postCCG_debug_data.mat',...
           'bz_spikes', 'parse_spikes', 'pairs', 'SampleRate', 'wintype');
    end
end
    
%% Step 2a: Set up plots
nplot = 5; % # pairs to plot in top/bottom of range
ref_epoch = 1;
% conn_type = 'ExcPairs'; % 'ExcPairs', 'InhPairs', 'GapPairs'

% Get boolean for pairs on different shanks only
cell1_shank = arrayfun(@(a) bz_spikes.shankID(a == bz_spikes.UID), ...
    pairs(ref_epoch).(conn_type)(:,1));
cell2_shank = arrayfun(@(a) bz_spikes.shankID(a == bz_spikes.UID), ...
    pairs(ref_epoch).(conn_type)(:,2));
diff_shank_bool = cell1_shank ~= cell2_shank;
pairs_diff_shank = pairs(ref_epoch).(conn_type)(diff_shank_bool,:);
% Exclude redundant pairs here!
[~, isort] = sort(pairs_diff_shank(:,3));  % sort from strongest ms_conn to weakest
if length(isort) >= nplot
    top = pairs_diff_shank(isort(1:nplot),:);
    bottom = pairs_diff_shank(isort((end-nplot+1):end),:);
else
    mid = floor(length(isort)/2);
    top = pairs_diff_shank(isort(1:mid),:);
    bottom = pairs_diff_shank(isort((mid+1):end),:);
end

pairs_plot = cat(3,bottom,top);


% set up figures and subplots
if plot_top_bot
    hbotc = figure(100); htopc = figure(101);
    hbotf = figure(102); htopf = figure(103);
    hcomb = cat(2, cat(1,hbotc,htopc), cat(1,hbotf, htopf));
    nfigs = 1;
else
    hcomb = cat(2, figure(100), figure(102));
    pairs_plot_all = pairs_diff_shank(isort,:);
    npairs_all = size(pairs_plot_all,1);
    nfigs = ceil(npairs_all/nplot);
end

% User specific plot settings.
if isempty(getenv('COMPUTERNAME'));  pos = [70 230 1660 1860]; a_offset = [0 1700 100 1800]'; b_offset = [0 0 -100 -100]'; 
elseif strcmp(getenv('COMPUTERNAME'), 'NATLAPTOP'); pos = [35 115 740 630]; a_offset = [0 50 700 800]'; b_offset = [0 -50 0 -50]'; end
if plot_top_bot
    arrayfun(@(a,b,c) set(a, 'Position', pos + [b c 0 0]), hcomb(:), a_offset, b_offset);
else
    arrayfun(@(a) set(a, 'Position', pos), hcomb(:));
end
   

%% Step 2b: Now plot everything
% implementation of plotting is not very pretty - want to accommodate
% plotting ALL pairs as well as just most/least significant pairs...
coarse_fine_text = {'coarse', 'fine'};
nepochs = length(epoch_names);
for nfig = 1:nfigs
    if ~plot_top_bot
        if nfig < nfigs
            pairs_plot = pairs_plot_all((nplot*(nfig-1)+1):nplot*nfig,:); % update pairs to plot
        elseif nfig == nfigs
            pairs_plot = pairs_plot_all((nplot*(nfig-1)+1):end,:); % update pairs to plot
        end
        if nfig > 1  % set up new figures
            try close 100; end; try close 102; end
            hcomb = cat(2, figure(100), figure(102)); arrayfun(@(a) set(a, 'Position', pos), hcomb(:));
        end
    end
    for top_bot = 1:2
        if ~plot_top_bot && top_bot == 2  % skip plotting bottom if plot_top_bot = false!
            continue
        end
        for coarse_fine = 1:2
            if coarse_fine == 1 % coarse
                duration = 0.02; binSize = 0.001; jscale_plot = 5;
            elseif coarse_fine == 2 % fine
                duration = 0.006; binSize = 1/SampleRate; jscale_plot = 1;
            end
            fig_use = figure(hcomb(top_bot, coarse_fine));
            for epoch_plot = 1:1:3
                
                for k = 1:nplot
                    try
                    cell1 = pairs_plot(k,1,top_bot);
                    cell2 = pairs_plot(k,2,top_bot);
                    pval = pairs_plot(k,3,top_bot);
                    res1 = parse_spikes(epoch_plot).spindices(...
                        parse_spikes(epoch_plot).spindices(:,2) == cell1,1)/1000;
                    res2 = parse_spikes(epoch_plot).spindices(...
                        parse_spikes(epoch_plot).spindices(:,2) == cell2,1)/1000;
                    [pvals, pred, qvals, ccgR, tR] = CCGconv(res1, res2, SampleRate, ...
                        binSize, duration, 'jscale', jscale_plot, 'alpha', 0.01, ...
                        'plot_output', get(fig_use, 'Number'), ...
                        'ha', subplot(nplot, 3, epoch_plot + (k-1)*nepochs),...
                        'wintype', wintype);
                    if epoch_plot == ref_epoch
                        title([epoch_names{epoch_plot} ' ' num2str(cell1) ' v ' num2str(cell2) ': ' ...
                            'p_{' num2str(pairs(epoch_plot).jscale) 'ms}= ' num2str(pval, '%0.2g')]);
                    else
                        if epoch_plot == 2 && k == 1
                            title({conn_type; [epoch_names{epoch_plot} ': ' num2str(cell1) ' v ' num2str(cell2)]});
                        else
                            title([epoch_names{epoch_plot} ': ' num2str(cell1) ' v ' num2str(cell2)]);
                        end
                    end
                    
                    % Turn off xlabels for all but bottom row for readability
                    if k < nplot
                        cur_ax = subplot(nplot, 3, epoch_plot + (k-1)*nepochs);
                        xlabel(cur_ax,'');
                        set(cur_ax,'XTick',[],'XTickLabel','');
                        last_xtick = get(cur_ax,'XTick');
                        last_xticklabel = get(cur_ax, 'XTickLabel');
                    end
                    catch ME
                        if strcmp(ME.identifier, 'MATLAB:badsubscript')
                            set(cur_ax,'XTick',last_xtick,'XTickLabel',last_xticklabel); % put xlabels back on bottom row for last page of plotting if not bottom row.
                        else
                            error('Error in pre_v_postCCG')
                        end
                    end
                end
            end
            if save_plots  % save all plots!
                printNK([session_name '_all_' conn_type '_jscale' num2str(jscale) '_' coarse_fine_text{coarse_fine} '_CCGs'],...
                    data_dir, 'hfig', fig_use, 'append', true);
            end
        end
    end
end
%% Step 2b: run CCG_jitter and plot out each as above, but only on good pairs!

if plot_jitter
    disp('Plotting jitter requires manual entry of pairs_plot and njitter params')
    keyboard
    %%
    % maximum 5 pairs to plot for now.
%     pairs_plot = [79 53; 45 15]; conn_type = 'ExcPairs'; %ExcPairs RoyMaze1.
    pairs_plot = [79 40; 20 45];  conn_type = 'InhPairs'; %InhPairs for RoyMaze1
    njitter = 100;
    alpha = 0.05;

    hjit_coarse = figure(105); hjit_fine = figure(106);
    hjit_comb = cat(1, hjit_coarse, hjit_fine);
    arrayfun(@(a,b,c) set(a, 'Position', pos + [b c 0 0]), hjit_comb(:), a_offset([ 1 3]), b_offset([1 3]));
    nplot = size(pairs_plot,1);
    for coarse_fine = 1:2
        if coarse_fine == 1
            duration = 0.02; binSize = 0.001; jscale = 5;
        elseif coarse_fine == 2
            duration = 0.002; binSize = 1/SampleRate; jscale = 1;
        end
        fig_use = figure(hjit_comb(coarse_fine));
        for epoch_plot = 1:1:3
            for k = 1:nplot
                cell1 = pairs_plot(k,1);
                cell2 = pairs_plot(k,2);
                res1 = parse_spikes(epoch_plot).spindices(...
                    parse_spikes(epoch_plot).spindices(:,2) == cell1,1)/1000;
                res2 = parse_spikes(epoch_plot).spindices(...
                    parse_spikes(epoch_plot).spindices(:,2) == cell2,1)/1000;
                [GSPExc,GSPInh,pvalE,pvalI,ccgR,tR,LSPExc,LSPInh,JBSIE,JBSII] = ...
                    CCG_jitter(res1, res2, SampleRate, binSize, duration, 'jscale', jscale, ...
                    'plot_output', get(fig_use, 'Number'), 'subfig', epoch_plot + (k-1)*nepochs, ...
                    'subplot_size', [nplot, 3], 'njitter', njitter, 'alpha', alpha);
                if strcmp(conn_type, 'InhPairs')
                    JBSI = max(JBSII); jb_type = 'JBSII_{max}= ';
                else
                    JBSI = max(JBSIE); jb_type = 'JBSIE_{max}= ';
                end
                if epoch_plot == ref_epoch
                    title({[epoch_names{epoch_plot} ' ' num2str(cell1) ' v ' num2str(cell2)]; ...
                        [jb_type num2str(JBSI)]});
                else
                    title({[jb_type num2str(JBSI)]; [epoch_names{epoch_plot} ': ' num2str(cell1) ' v ' num2str(cell2)]});
                end
            end
        end
        
    end
    
end
%%


end


