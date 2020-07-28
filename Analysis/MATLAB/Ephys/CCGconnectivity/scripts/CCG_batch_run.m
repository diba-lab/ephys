% CCG batch run script
if strcmp(getenv('COMPUTERNAME'), 'NATLAPTOP')
    data_dir = 'C:\Users\Nat\Documents\UM\Working\HiroData\wake_new';
elseif isempty(getenv('COMPUTERNAME'))
    data_dir = '/data/Working/Other Peoples Data/HiroData/wake_new';
end

session_names = {'TedMaze1', 'TedMaze2', 'TedMaze3', 'KevinMaze1'}; %{'RoyMaze1', 'RoyMaze2', 'RoyMaze3', 'TedMaze1',...
%     'TedMaze2', 'TedMaze3', 'KevinMaze1'};
conn_types = {'ExcPairs', 'InhPairs', 'GapPairs'};
jscale_use = [5]; % [1 5];
alpha = 0.05;
plot_jitter = true;
njitter = 1000;
save_jitter = true;
jitter_debug = false;
screen_type = 'two_prong';
for j = 1:length(jscale_use)
    jscale = jscale_use(j);
    hw = waitbar(0, ['running CCG\_batch\_run for jscale=' num2str(jscale) ' ms']);
    set(hw,'Position', [1420 550 220 34]);
    n = 0;
    for session = 1:length(session_names)
        session_use = session_names{session};
        for conn_num = 1:length(conn_types)
            conn_type = conn_types{conn_num};
            pre_v_postCCG(fullfile(data_dir,'wake-spikes.mat'), session_use, ...
                'alpha', alpha, 'jscale', jscale, ...
                'conn_type', conn_type, 'plot_jitter', plot_jitter, ...
                'save_plots', true, 'save_jitter', save_jitter, ...
                'jitter_debug', jitter_debug, 'njitter', njitter)
            n = n+1; waitbar(n/(length(session_names)*length(conn_types)), hw);
        end
    end
    close(hw);
end

    