function [outputArg1,outputArg2] = pre_v_postCCG(spike_data_fullpath, session_name, varargin)
% pre_v_postCCG(spike_data_path, session_name)
%   Identify ms connectivity in ANY of the PRE-rest (3hr) , MAZE (3hr) or
%   POST-sleep (3hr) sessions and plot CCGs with stats and stuff
%   side-by-side.

ip = inputParser;
ip.addRequired('spike_data_fullpath', @isfile);
ip.addRequired('session_name', @ischar);
ip.addParameter('alpha', 0.01, @(a) a > 0 && a < 0.25);
ip.addParameter('jscale', 5, @(a) a > 0 && a < 10);
ip.parse(spike_data_fullpath, session_name, varargin{:});
alpha = ip.Results.alpha;
jscale = ip.Results.jscale;

epoch_names = {'Pre', 'Maze', 'Post'};
%% Step 0: load spike and behavioral data, parse into pre, track, and post session
[data_dir, name, ~] = fileparts(spike_data_fullpath);
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
for j = 1:nepochs
    cell_inds = arrayfun(@(a) find(bz_spikes.UID == a), bz_spikes.UID); 
    [ExcPairs, InhPairs, GapPairs, RZero] = ...
        EranConv_group(parse_spikes(j).spindices(:,1)/1000, parse_spikes(j).spindices(:,2), ...
        bz_spikes.UID, SampleRate, jscale, alpha, bz_spikes.shankID(cell_inds));
    pairs(j).ExcPairs = ExcPairs;
    pairs(j).InhPairs = InhPairs;
    pairs(j).GapPairs = GapPairs;
    pairs(j).RZero = RZero;
end
    
%% Step 2a: Plot out each pair, put star on sessions with ms connectivity
nplot = 5; % # pairs to plot in top/bottom of range
ref_epoch = 1;
ms_type = 'ExcPairs'; % 'ExcPairs', 'InhPairs', 'GapPairs'
[psort, isort] = sort(pairs(ref_epoch).(ms_type)(:,3));  % sort from strongest ms_conn to weakest
top = pairs(ref_epoch).(ms_type)(isort(1:nplot),:);
bottom = pairs(ref_epoch).(ms_type)(isort((end-nplot):end,:));
pairs_plot = cat(3,bottom,top);

% set up figures and subplots
hbot = figure(100); htop = figure(101);
hcomb = cat(1,hbot,htop);

for epoch_plot = 1:2:3
    for top_bot = 1:2
        figure(hcomb(top_bot));
        for k = 1:nplot
            cell1 = pairs_plot(k,1,top_bot);
            cell2 = pairs_plot(k,2,top_bot);
            res1 = parse_spikes(epoch).spindices(parse_spikes(epoch).spindices(:,2) == cell1,1);
            res2 = parse_spikes(epoch).spindices(parse_spikes(epoch).spindices(:,2) == cell2,1);
            [pvals, pred, qvals, ccgR, tR] = CCGconv(res1, res2, SampleRate, ...
                1/SampleRate, 0.05, 'jscale', 1, 'alpha', 0.01, ...
                'plot_output', get(figure(hcomb(top_bot)), 'Number'), ...
                'ha', subplot(nplot, 3, epoch_plot + (nplot-1)*epoch_plot));
            title([epoch_names{epoch_plot} ': ' num2str(cell1) ' v ' num2str(cell2)]);
        end
    end


%% Step 2b: run CCG_jitter and plot out each as above, but only on good pairs!

end


