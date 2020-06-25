data_folder = '/data/Working/Other Peoples Data/HiroData/';
sleepspikes = importdata(fullfile(data_folder,'/sleep/sleep-spikes.mat'));
wakespikes = importdata(fullfile(data_folder, 'wake_new/wake-spikes.mat'));

%% Screen all interneuron pairs with convolution method

%% Run through all interneuron pairs with jitter method
time_to_sec=1/(1000*1000);  
njitter = 100;
alpha = 0.05;
SampleRate=30000;
time_scale = 'coarse'; % options = 'coarse' or 'fine'
session_use = 'RoySleep1';
if regexpi(session_use,'sleep') || regexpi(session_use,'rest')
    spike_data = sleepspikes.(session_use);
elseif regexpi(session_use,'maze')
    spike_data = wakespikes.(session_use);
end

switch time_scale
    case 'coarse'
        jscale = 5;
        BinSize = 0.001;
        Duration = 0.02;
    case 'fine'
        jscale = 1;
        BinSize = 1/SampleRate;
        Duration = 0.002;
end

interneurons = find(arrayfun(@(a) a.quality == 8, spike_data));
neurons_use = [9 87];
shank = arrayfun(@(a) a.id(1), spike_data(neurons_use));
nplots = length(neurons_use)*(length(neurons_use)-1)/2;
fig_num = max(arrayfun(@(a) a.Number, findobj('type','figure'))) + 1;
if isempty(fig_num); fig_num = 1; end
n = 1; subfig = 1; figure(fig_num); subplot(4,4,1);
hw = waitbar(0,'Running CCG jitter...');
for j = 1:(length(neurons_use)-1)
    n1 = neurons_use(j);
    shank1 = shank(j);
    for k = (j+1):length(neurons_use)
        n2 = neurons_use(k);
        shank2 = shank(k);
        if mod(n,16) == 0            
            fig_num = fig_num+1;
            figure(fig_num); subplot(4,4,1);
            subfig = 1;
        end
        if shank1 ~= shank2
            CCG_jitter(spike_data(n1).time*time_to_sec, spike_data(n2).time*time_to_sec,...
                SampleRate, BinSize, Duration, 'jscale', jscale, 'njitter', njitter, ...
                'alpha', alpha, 'plot_output', fig_num, 'subfig', subfig);
            title(gca, [num2str(n1) ' v ' num2str(n2)]);
        end       
        waitbar(n/nplots, hw);
        subfig = subfig + 1; n = n+1;
    end
end
close(hw);

%% Plot a specific CCG divided up into increments to track across recording session
time_to_sec=1/(1000*1000);  
njitter = 100;
alpha = 0.05;
SampleRate=30000;
time_scale = 'fine_wide'; % options = 'coarse' or 'fine'
session_use = 'RoySleep1';
nblocks = 4;
if regexpi(session_use,'sleep') || regexpi(session_use,'rest')
    spike_data = sleepspikes.(session_use);
elseif regexpi(session_use,'maze')
    spike_data = wakespikes.(session_use);
end

switch time_scale
    case 'coarse'
        jscale = 5;
        BinSize = 0.001;
        Duration = 0.02;
    case 'fine'
        jscale = 1;
        BinSize = 1/SampleRate;
        Duration = 0.002;
    case 'fine_wide'
        jscale = 1;
        BinSize = 1/SampleRate;
        Duration = 0.01;
end

interneurons = find(arrayfun(@(a) a.quality == 8, spike_data));
neurons_use = [35 87];
shank = arrayfun(@(a) a.id(1), spike_data(neurons_use));
nplots = length(neurons_use)*(length(neurons_use)-1)/2*nblocks;
fig_num = max(arrayfun(@(a) a.Number, findobj('type','figure'))) + 1;
if isempty(fig_num); fig_num = 1; end
set(figure(fig_num), 'Position', [390 1250 2945 480]);
n = 1; subfig = 1; figure(fig_num); subplot(1,nblocks,1);
hw = waitbar(0,'Running CCG jitter...');
for j = 1:(length(neurons_use)-1)
    n1 = neurons_use(j);
    shank1 = shank(j);
    dur1 = diff(spike_data(n1).time([1 end]));
    block_edges = spike_data(n1).time(1) + (0:(1/nblocks):1)*dur1;
    for k = (j+1):length(neurons_use)
        n2 = neurons_use(k);
        shank2 = shank(k);
        figure(fig_num); subplot(1, nblocks + 1, 1);
        for block = 0:nblocks
            if shank1 ~= shank2
                if block == 0
                    block_bool1 = true(size(spike_data(n1).time));
                    block_bool2 = true(size(spike_data(n2).time));
                else
                    block_bool1 = spike_data(n1).time >= block_edges(block) & ...
                        spike_data(n1).time <= block_edges(block + 1);
                    block_bool2 = spike_data(n2).time >= block_edges(block) & ...
                        spike_data(n2).time <= block_edges(block + 1);
                end
                CCG_jitter(spike_data(n1).time(block_bool1)*time_to_sec, spike_data(n2).time(block_bool2)*time_to_sec,...
                    SampleRate, BinSize, Duration, 'jscale', jscale, 'njitter', njitter, ...
                    'alpha', alpha, 'plot_output', fig_num, 'subfig', block + 1, ...
                    'subplot_size', [1, 5]);
                if block == 0
                    title(gca, [num2str(n1) ' v ' num2str(n2) ' Whole Session']);
                else
                    title(gca, [num2str(n1) ' v ' num2str(n2) ' Block ' num2str(block)]);
                end
            end
            waitbar(n/nplots, hw);
            n = n+1;
        end
        fig_num = fig_num + 1;
    end
end
close(hw);


%% Can't figure out sample rate - I can't get anything approaching
% 1/30000 in the fine CCGs - seems like anything on the same shank
% is separated by a minimum 0.567 ISI!

time_to_sec=1/(1000*1000);  
SampleRate = 30000;
BinSize=50; HalfBins=25;
jscale=5;
njitter=500;
alpha=0.01;
plot_output=true;
plot_type = 'both';  % options = 'both', 'gross', 'fine'
session_use = 'RoySleep1';

neurons_use = 1:length(sleepspikes.(session_use));
neurons_use = [2 156];
for i1 = 1:length(neurons_use)
    res1 = sleepspikes.(session_use)(neurons_use(i1)).time';
    n1 = neurons_use(i1);
    for i2 = (i1+1):length(neurons_use)
        n2 = neurons_use(i2);
        res2 = sleepspikes.(session_use)(neurons_use(i2)).time';
        
        % res1 = wakespikes.RoyMaze1(3).time';
        % res2 = wakespikes.RoyMaze1(4).time';
        
        %                 [GSPExc,GSPInh,pvalE,pvalI,ccgR,tR,LSPExc,LSPInh,JBSIE,JBSII]=...
        %                     CCG_jitter(res1,res2,SampleRate,BinSize,HalfBins,jscale,njitter,alpha,plot_output);

        
        [ccg, ccgf, t, tf] = deal([]);
        [hc, hf] = deal(gobjects(1));
        
        if strcmpi(plot_type, 'gross') || strcmpi(plot_type, 'both')
            [ccg, t] = CCG([res1*time_to_sec; res2*time_to_sec], [ones(size(res1)); 2*ones(size(res2))], ...
                'Fs', time_to_sec, 'binSize', 0.001, 'duration', .05, 'norm', 'counts');
            hc = figure;
        end
        if strcmpi(plot_type, 'fine') || strcmpi(plot_type, 'both')
            [ccgf, tf] = CCG([res1*time_to_sec; res2*time_to_sec], [ones(size(res1)); 2*ones(size(res2))], ...
                'Fs', time_to_sec, 'binSize', 1/SampleRate, 'duration', 0.002, 'norm', 'counts');
            hf = figure;
        end
        hcomb = cat(1,hc,hf);
        ccg_comb{1} = ccg; ccg_comb{2} = ccgf;
        t_comb{1} = t; t_comb{2} = tf;
        switch plot_type; case 'both'; plot_inds = [1 2]; case 'gross'; plot_inds = 1; case 'fine'; plot_inds = 2; end
        for m = plot_inds
            figure(hcomb(m));
            neurons = [n1, n2];
            for j = 1:2
                for k = 1:2
                    subplot(2,2,(k-1)*2+j);
                    bar(t_comb{m}*1000,squeeze(ccg_comb{m}(:,j,k)));
                    title([num2str(neurons(j)) ' vs ' num2str(neurons(k))]);
                    xlabel('Time Lag (ms)');
                    ylabel('Count')
                end
            end
        end
    end
end

%% Check for minimum difference between spikes - why is there a 0.567 cap?
time_to_sec=1/(1000*1000);
sleep_session = 'RoySleep1';
spike_data = sleepspikes.(sleep_session);
n_units = length(spike_data);

min_ISI_ms=nan(n_units, n_units);
hw = waitbar(0,['Calculating ISIs for ' sleep_session]);
niters = n_units*(n_units-1)/2;
n = 0;
for j = 1:n_units
    for k = j:n_units
        if j == k
            min_ISI_ms(j,k) = min(diff(spike_data(j).time))...
                *time_to_sec*1000;
        elseif j ~= k
            min_ISI_ms(j,k) = min(diff(sort(cat(2, spike_data(j).time,...
                spike_data(k).time))))*time_to_sec*1000;
        end
        n = n + 1;
        waitbar(n/niters, hw);
    end
end
close(hw)

% Cut out any super-long minimum ISIs
[i,j] = find(min_ISI_ms > 100);
min_ISIadj = min_ISI_ms;
min_ISIadj(i,j) = nan;

%% Now plot
figure; histogram(min_ISIadj,0.033333:0.033333:1)
xlabel('Minimum ISI (ms)'); ylabel('Count'); title(sleep_session);
                
