function [nstable, npotentiated, ndepressed, ntotal, bool_cell] = ...
    pre_v_post_stability(spike_data_fullpath, session_name, varargin)
%   [nstable, npotentiated, ndepressed, ntotal, bool_cell] = ...
%   pre_v_post_stability(spike_data_fullpath, session_name, varargin)
%
%   Track stability of millisecond synchrony from PRE->POST epochs
%   Uses data processed by pre_v_postCCG.
%
ip = inputParser;
ip.addRequired('spike_data_fullpath', @isfile);
ip.addRequired('session_name', @ischar);
ip.addParameter('alpha', 0.05, @(a) a > 0 && a < 0.25);
ip.addParameter('jscale', 5, @(a) a > 0 && a < 10);
ip.addParameter('debug', false, @islogical);
ip.addParameter('conn_type', 'ExcPairs', @(a) ismember(a, ...
    {'ExcPairs', 'InhPairs', 'GapPairs'}));
ip.addParameter('wintype', 'gauss', @(a) ismember(a, ...
    {'gauss', 'rect', 'triang'})); % convolution window type
ip.addParameter('plot_conv', true, @islogical);
ip.addParameter('plot_jitter', false, @islogical); 
ip.addParameter('save_plots', true, @islogical); % save all the plots you make 
ip.addParameter('jitter_debug', false, @islogical); % used for debugging jitter code only
ip.addParameter('save_jitter', false, @islogical); % save jitter results for fast recall!
ip.addParameter('njitter', 100, @(a) a > 0 && round(a) == a);
ip.addParameter('screen_type', 'one_prong', @(a) ismember(a, ...
    {'one_prong', 'two_prong'})); % one_prong = @jscale and alpha specified, two_prong = @alpha specified + EITHER 5ms or 1ms convolution window.
ip.addParameter('combine_epochs', false, @islogical)
ip.addParameter('pair_type_plot', 'all', @(a) ismember(a, ...
    {'all', 'pyr-pyr', 'int-int', 'pyr-int'}));
ip.addParameter('pairs_list', [], @(a) isnumeric(a) && size(a,2) == 2);
ip.addParameter('for_grant', false, @islogical);  % simplify plots for grant prelim data plots!
ip.parse(spike_data_fullpath, session_name, varargin{:});

alpha = ip.Results.alpha;
jscale = ip.Results.jscale;
debug = ip.Results.debug;
wintype = ip.Results.wintype;
conn_type = ip.Results.conn_type;
plot_conv = ip.Results.plot_conv;
plot_jitter = ip.Results.plot_jitter;
save_plots = ip.Results.save_plots;
jitter_debug = ip.Results.jitter_debug;
njitter = ip.Results.njitter;
save_jitter = ip.Results.save_jitter;
screen_type = ip.Results.screen_type;
combine_epochs = ip.Results.combine_epochs;
pair_type_plot = ip.Results.pair_type_plot;
pairs_list = ip.Results.pairs_list;
for_grant = ip.Results.for_grant;

nplot = 4; % # pairs to plot per figure

% Make sure you look at convolution plots prior to running jitter.
if plot_jitter; plot_conv = false; end
%% Step 0: load spike and behavioral data, parse into pre, track, and post session

[data_dir, name, ~] = fileparts(spike_data_fullpath);
if ~debug
load(spike_data_fullpath, 'spikes')
if contains(name, 'wake')
    load(fullfile(data_dir, 'wake-behavior.mat'), 'behavior');
    load(fullfile(data_dir, 'wake-basics.mat'),'basics');
elseif contains(name, 'sleep') % this can be used later for parsing NREM v REM v other periods...
    load(fullfile(data_dir, 'sleep-behavior.mat'), 'behavior');
    load(fullfile(data_dir, 'sleep-basics.mat'), 'basics');
end
SampleRate = basics.(session_name).SampleRate;

% Make data nicely formatted to work with buzcode
bz_spikes = Hiro_to_bz(spikes.(session_name), session_name);

% Pull out PRE, MAZE, and POST time limits
nepochs_plot = 3; % used to keep plots nice!
if contains(name, 'wake')
    if ~combine_epochs
        nepochs = 3;
        save_name_append = '';
        epoch_names = {'Pre', 'Maze', 'Post'};
        time_list = behavior.(session_name).time/1000; % convert time list to milliseconds
    
    elseif combine_epochs
        nepochs = 1;
        epoch_names = {'Pre-Maze-Post Combined'};
        time_list = [behavior.(session_name).time(1)/1000, ...
            behavior.(session_name).time(end)/1000];
        save_name_append = '_combined';
    end
elseif contains(name, 'sleep')
    nepochs = 3;
    
    % Name epochs nicely (up to 5 maximum!)
%     prefixes = {'First', 'Second', 'Third', 'Fourth', 'Fifth'};
%     epoch_names = cellfun(@(a) ['Sleep ' a ' ' num2str(1) '/' num2str(nepochs)], ...
%         prefixes(1:nepochs), 'UniformOutput', false);
    epoch_names = arrayfun(@(a) ['Sleep Block ' num2str(a)], 1:nepochs, ...
        'UniformOutput', false);
    epoch_times = (0:nepochs)*diff(behavior.(session_name).time/1000)/nepochs + ...
        behavior.(session_name).time(1)/1000;
    save_name_append = ['_' num2str(nepochs) 'epochs'];
    time_list = nan(nepochs,2);
    for j = 1:nepochs
        time_list(j,:) = [epoch_times(j), epoch_times(j+1)];
    end
end

nneurons = length(spikes.(session_name));
for j = 1:nepochs
    epoch_bool = bz_spikes.spindices(:,1) >= time_list(j,1) ...
        & bz_spikes.spindices(:,1) <= time_list(j,2); % ID spike times in each epoch
    parse_spikes(j).spindices = bz_spikes.spindices(epoch_bool,:); % parse spikes by epoch into this variable
end
% Figure out if pyramidal or inhibitory
cell_type = repmat('p', 1, length(bz_spikes.quality));
cell_type(bz_spikes.quality == 8) = 'i';

%% Step 1: Screen for ms connectivity by running EranConv_group on each session 
alpha_orig = alpha; jscale_orig = jscale;
if strcmp(screen_type, 'one_prong')
    jscale_use = jscale;
elseif strcmp(screen_type, 'two_prong')
    jscale_use = [1 5];
end
for js = 1:length(jscale_use)
    try
        if ~exist('pairs','var')  % the logic in the if/else statement is terrible.
            load(fullfile(data_dir,[session_name '_jscale' num2str(jscale_use(js)) '_alpha' ...
                num2str(round(alpha*100)) '_pairs' save_name_append]), ...
                'pairs', 'jscale', 'alpha')
        elseif strcmp(screen_type,'two_prong') && js >= 2
            if pairs(1).jscale == 1
                pairs_comb(1).pairs = pairs;
                load(fullfile(data_dir,[session_name '_jscale' num2str(jscale_use(js)) '_alpha' ...
                    num2str(round(alpha*100)) '_pairs' save_name_append]),...
                    'pairs', 'jscale', 'alpha')
                pairs_comb(2).pairs = pairs; % concatenate!
                
            else
                error('Error in pre_v_postCCG')
            end
            
        end
        if alpha_orig ~= alpha || jscale_use(js) ~= jscale
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
                bz_spikes.UID(cell_inds), SampleRate, jscale_use(js), alpha, bz_spikes.shankID(cell_inds), ...
                wintype);
            pairs(j).ExcPairs = ExcPairs;
            pairs(j).InhPairs = InhPairs;
            pairs(j).GapPairs = GapPairs;
            pairs(j).RZero = RZero;
            pairs(j).jscale = jscale_use(js);
        end
        save(fullfile(data_dir,[session_name '_jscale' num2str(jscale_use(js)) '_alpha' ...
            num2str(round(alpha*100)) '_pairs' save_name_append]), ...
            'pairs', 'jscale', 'alpha')
    end
end

% Now concatenate all cell pairs that pass EITHER timescale criteria if
% using two-pronged screening approach
if strcmp(screen_type, 'two_prong')
    
    % concatenate pairs 
    for k = 1:nepochs
        pairs(k).(conn_type) = cat(1, pairs_comb(1).pairs(k).(conn_type),...
            pairs_comb(2).pairs(k).(conn_type));
        
        % Identify unique pairs
        pair_row_inds = arrayfun(@(a,b) find(all(pairs(k).(conn_type)(:,1:2) == [a b],2)), ...
            pairs(k).(conn_type)(:,1), pairs(k).(conn_type)(:,2), ...
            'UniformOutput', false); % this identifies all row indices that match a given cell-pair
        
        unique_pairs = unique(cellfun(@(a) a(1), pair_row_inds)); % keep only the first of a redundant pair
        
        % Keep only unique pairs
        pairs(k).(conn_type) = pairs(k).(conn_type)(unique_pairs,:);
    end
    
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
    
%% Step 2a: Identify pairs that passed the screening test above in Step 1
for ref_epoch = 1:nepochs
    if ~isempty(pairs(ref_epoch).(conn_type))
        % Get boolean for pairs on different shanks only
        cell1_shank = arrayfun(@(a) bz_spikes.shankID(a == bz_spikes.UID), ...
            pairs(ref_epoch).(conn_type)(:,1));
        cell2_shank = arrayfun(@(a) bz_spikes.shankID(a == bz_spikes.UID), ...
            pairs(ref_epoch).(conn_type)(:,2));
        diff_shank_bool = cell1_shank ~= cell2_shank;
        pairs_diff_shank = pairs(ref_epoch).(conn_type)(diff_shank_bool,:);
        
        % Aggregate all pairs based on epoch in which they obtained ms
        % connectivity.
        if ~exist('pairs_plot_all','var') % set up pairs to plot with nans in non-significant epochs
            pairs_plot_all = cat(2, pairs_diff_shank(:,1:2), ...
                nan(size(pairs_diff_shank,1),ref_epoch-1), pairs_diff_shank(:,3));
        elseif exist('pairs_plot_all','var')
            % First ID cell pairs with ms_connectivity in multiple epochs
            temp = arrayfun(@(a,b) find(all(pairs_plot_all(:,1:2) == [a b],2)), ...
                pairs_diff_shank(:,1), pairs_diff_shank(:,2), 'UniformOutput', false);
            redundant_pairs = cat(2, cat(1,temp{:}), find(~cellfun(@isempty, temp)));
            unique_pairs = find(cellfun(@isempty, temp));
            
            % Now add in pvalues for current epoch
            pairs_plot_all = [pairs_plot_all nan(size(pairs_plot_all,1),1)];  %#ok<AGROW>
            if ~isempty(redundant_pairs)
                pairs_plot_all(redundant_pairs(:,1), ref_epoch + 2) = ...
                    pairs_diff_shank(redundant_pairs(:,2),3);
            end
            
            % Now add in new cell-pairs that gain ms connectivity in that epoch
            if ~isempty(unique_pairs)
                pairs_plot_all = cat(1, pairs_plot_all, ...
                    cat(2, pairs_diff_shank(unique_pairs,1:2), nan(length(unique_pairs),...
                    ref_epoch - 1), pairs_diff_shank(unique_pairs,3)));
            end
            
            
        end
    elseif isempty(pairs(ref_epoch).(conn_type)) && ref_epoch == 3  && ...
            size(pairs_plot_all, 2) < nplot % edge-case
        ncol_append = nplot - size(pairs_plot_all,2);
        pairs_plot_all = cat(2, pairs_plot_all, nan(size(pairs_plot_all,1), ncol_append));
    end
end

% Pull out only specific pairs if specified!
if ~isempty(pairs_list)
    pairs_keep_bool = false(size(pairs_plot_all, 1), 1);
    for j = 1:size(pairs_list,1)
        pairs_keep_bool = pairs_keep_bool | ...
            (pairs_plot_all(:,1) == pairs_list(j,1) & ...
            pairs_plot_all(:,2) == pairs_list(j,2));
    end
    pairs_plot_all = pairs_plot_all(pairs_keep_bool, :);
end


% Get all pyr-pyr pairs!
c1type = arrayfun(@(a) cell_type(a == bz_spikes.UID), pairs_plot_all(:,1));
c2type = arrayfun(@(a) cell_type(a == bz_spikes.UID), pairs_plot_all(:,2));
pp_pairs = pairs_plot_all(c1type == 'p' & c2type == 'p',:);

pages_look = [];
for j = 1:size(pp_pairs,1) 
    pages_look = [pages_look ...
        ceil(find(pairs_plot_all(:,1) == pp_pairs(j,1) & ...
        pairs_plot_all(:,2) == pp_pairs(j,2))/nplot)]; 
end

% append on pages where you should lookup pyr-pyr pairs
pp_pairs = [pp_pairs, pages_look'];  

%% Second 3: now quantify numbers of stable cells!!!
stable = [1 1];
potentiated = [0 1];
depressed = [1 0];

% Stable cells: ms synchrony during PRE and POST
stable_bool = pairs_plot_all(:,3) < alpha ...
    & pairs_plot_all(:,5) < alpha;
nstable = sum(stable_bool);

% Potentiated: ms synchrony emerges during POST
potentiated_bool = isnan(pairs_plot_all(:,3)) ...
    & pairs_plot_all(:,5) < alpha;
npotentiated = sum(potentiated_bool);

% Depressed: ms synchrony during PRE disappears during POST
depressed_bool = pairs_plot_all(:,3) < alpha ...
    & isnan(pairs_plot_all(:,5));
ndepressed = sum(depressed_bool);

% track only
track_bool = isnan(pairs_plot_all(:,3)) & ...
    isnan(pairs_plot_all(:,5));
ntrack = sum(track_bool);

ntotal = nstable + npotentiated + ndepressed + ntrack;

% dump booleans into a cell array
bool_cell = {'Stable', 'Potentiated', 'Depressed', 'Track_only'; ...
    stable_bool, potentiated_bool, depressed_bool, track_bool};
    

if ntotal == size(pairs_plot_all,1)
    disp('Cross check pans out - all good')
else
    disp('Numbers don''t add up - check out code!!!')
end

%% Plot it
figure;
set(gcf, 'position', [1450 1300 1200 1400])
bar(subplot(2,1,1), [1 2 3 5], [nstable npotentiated ndepressed ntrack]/ntotal*100)
hold on
plot(subplot(2,1,1), [4 4], get(subplot(2,1,1),'ylim'), 'k--')
set(subplot(2,1,1), 'xticklabels',{'Stable', 'Potentiated', 'Depressed', 'Track Only'})
ylabel('Percent of synchronous cell pairs')
title([session_name ': ' conn_type])
set(gca,'box', 'off')

bar(subplot(2,1,2), [1 2 3 5], [nstable npotentiated ndepressed ntrack])
hold on
plot(subplot(2,1,2), [4 4], get(subplot(2,1,1),'ylim'), 'k--')
set(subplot(2,1,2), 'xticklabels',{'Stable', 'Potentiated', 'Depressed', 'Track Only'})
ylabel('Number synchronous cell pairs')
set(gca,'box', 'off')

end
