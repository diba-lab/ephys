%% CCG quantifcation for grant review rebuttal
base_dir = '/data/Working/Other Peoples Data/HiroData/wake_new';
%% load in pairs and quantify
session = 'RoyMaze1';
load(fullfile(base_dir, [session '_jscale1_alpha5_pairs.mat']))

%% Run the following to loop through and get breakdown for all sessions

wake_sessions = {'RoyMaze1', 'RoyMaze2', 'RoyMaze3', 'TedMaze1', ...
    'TedMaze2', 'TedMaze3', 'KevinMaze1'}; 

conn_type = 'InhPairs';

for j = 1:length(wake_sessions)
    pre_v_post_stability(fullfile(base_dir, 'wake-spikes.mat'), ...
        wake_sessions{j}, 'conn_type', conn_type)
    printNK([wake_sessions{j} '_wake_stability_breakdown_' conn_type '.pdf'], ...
        'ms_synchrony_rebuttal')
end


