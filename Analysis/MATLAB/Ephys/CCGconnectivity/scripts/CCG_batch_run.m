% CCG batch run script
if strcmp(getenv('COMPUTERNAME'), 'NATLAPTOP')
    data_dir = 'C:\Users\Nat\Documents\UM\Working\HiroData';
elseif isempty(getenv('COMPUTERNAME'))
    data_dir = '/data/Working/Other Peoples Data/HiroData';
end

wake_sessions = {'RoyMaze1', 'RoyMaze2', 'RoyMaze3', 'TedMaze1', ...
    'TedMaze2', 'TedMaze3', 'KevinMaze1'}; 

grant_pairs.RoySleep1 = [120 5; 103 21; 23 38; 2 67; 94 8; 23 37; 87 30; 120 50];
grant_pairs.RoyMaze1 = [113 122; 16 26; 79 62];

close all
close hidden

session_names = {'RoyMaze1'}; 
conn_types = {'ExcPairs'}; % {'ExcPairs', 'InhPairs', 'GapPairs'};
jscale_use = [5]; % [1 5];
alpha = 0.05;
plot_jitter = true;
njitter = 500;
save_jitter = false;
jitter_debug = false;
screen_type = 'two_prong';
combine_epochs = false;
pair_type_plot = 'all';
for_grant = true;

% Enter in specific pairs to plot here, keep empty (e.g. []) to plot all
% cells that pass the screen.
pairs_filter_list = grant_pairs;

for j = 1:length(jscale_use)
    jscale = jscale_use(j);
    hw = waitbar(0, ['running CCG\_batch\_run for jscale=' num2str(jscale) ' ms']);
    set(hw,'Position', [1420 550 220 34]);
    n = 0;
    for session = 1:length(session_names)
        session_use = session_names{session};
        if ~isempty(pairs_filter_list)
            pairs_filter = pairs_filter_list.(session_use);
        end
        if contains(session_use, 'Sleep')
            file_load = fullfile(data_dir, 'sleep', 'sleep-spikes.mat');
        elseif contains(session_use, 'Maze')
            file_load = fullfile(data_dir, 'wake_new', 'wake-spikes.mat');
        end
        for conn_num = 1:length(conn_types)
            conn_type = conn_types{conn_num};
            pre_v_postCCG(file_load, session_use, ...
                'alpha', alpha, 'jscale', jscale, ...
                'conn_type', conn_type, 'plot_jitter', plot_jitter, ...
                'save_plots', true, 'save_jitter', save_jitter, ...
                'jitter_debug', jitter_debug, 'njitter', njitter, ...
                'combine_epochs', combine_epochs, 'pair_type_plot', pair_type_plot, ...
                'pairs_list', pairs_filter, 'for_grant', for_grant)
            n = n+1; waitbar(n/(length(session_names)*length(conn_types)), hw);
        end
    end
    close(hw);
end


    