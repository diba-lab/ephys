% CCG batch run script
if strcmp(getenv('COMPUTERNAME'), 'NATLAPTOP')
    data_dir = 'C:\Users\Nat\Documents\UM\Working\HiroData\wake_new';
elseif isempty(getenv('COMPUTERNAME'))
    data_dir = '/data/Working/Other Peoples Data/HiroData/wake_new';
end

session_names = {'RoyMaze1'}; %{'RoyMaze1', 'RoyMaze2', 'RoyMaze3', 'TedMaze1',...
    % 'TedMaze2', 'TedMaze3', 'KevinMaze1'};
conn_types = {'GapPairs'}; %{'ExcPairs', 'InhPairs', 'GapPairs'};
jscale = 1;
alpha = 0.05;
for session = 1:length(session_names)
    session_use = session_names{session};
    for conn_num = 1:length(conn_types)
        conn_type = conn_types{conn_num};
        pre_v_postCCG(fullfile(data_dir,'wake-spikes.mat'), session_use, ...
            'alpha', alpha, 'jscale', jscale, ...
            'conn_type', conn_type, 'plot_jitter', false, ...
            'plot_top_bot', false, 'save_plots', true)
    end
end

    