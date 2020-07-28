function [] = plot_finalCCGs(spike_data_fullpath, session_name, conn_type, ...
    varargin)
%  plot_finalCCGs(spike_data_fullpath, session_name, varargin)
%   Plot final pairs of cells that pass jitter test as millisecond
%   connected cells.

%% Step 0: Parse inputs
ip = inputParser;
ip.addRequired('spike_data_fullpath', @isfile);
ip.addRequired('session_name', @ischar);
ip.addRequired('conn_type', @ischar);
ip.addParameter('alpha', 0.05, @(a) a > 0 && a < 0.25);
ip.addParameter('njitter', 100, @(a) a > 0 && round(a) == a);
ip.parse(spike_data_fullpath, session_name, conn_type, varargin{:});
alpha = ip.Results.alpha;
njitter_use = ip.Results.njitter;

[data_dir, name, ~] = fileparts(spike_data_fullpath);
%% Step 1: try to load 1ms and 5m jitter data
scale = {'coarse', 'fine'};
for j = 1:length(scale)
    if strcmp(scale{j}, 'coarse'); jscale = 5; else; jscale = 1; end
    jitter_filename = fullfile(data_dir, [session_name '_' ...
        conn_type '_jscale' num2str(jscale) ...
        '_alpha' num2str(round(alpha*100)) '_jitterdata.mat']);
    load(jitter_filename, 'njitter', 'jitter_data');
    if njitter_use ~= njitter
        disp('njitter specified does not match that found in previously run data')
        error('Re-run CCG_jitter with updated njitter value and save data')
    end
    jitter_data.(scale).jitter_data = jitter_data;
    jitter_data.(scale).njitter = njitter;
end

%% Step 2: Perform 2-pronged test - consider any cells that
% pass 1ms OR 5ms convolution test.  Re-write "pairs" step in
% Pre_to_postCCG as a function. Might need to re-run CCG_batch_run first to
% consider ANY cells that pass EITHER filter first.

% Step 3: Now test and see which pass either the 5ms or 1ms jitter test
% applying the same criteria as KD.

% Step 4: plot! if flagged only?

% Step 5: spit out JBSI values across all epochs?

% Step 6: think about how to make this generalize to sleep?

end

