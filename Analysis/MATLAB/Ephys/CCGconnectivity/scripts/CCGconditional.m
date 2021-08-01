%% Script to create CCGs based on whether or not two spikes occur in
% quick succession.

duration = 0.007;  % total width of CCG plot...
data_folder = '/data/Working/Other Peoples Data/HiroData';


%% Load in data for the appropriate session
epoch_num = 2; %1 = pre, 2 = maze, 3 = post
[parse_spikes, SampleRate] = load_hiro_data(fullfile(data_folder,...
     'wake_new/wake-spikes.mat'), 'RoyMaze1');


sp_times = parse_spikes.spindices(:,1);
cell_nos = parse_spikes.spindices(:,2);

%% Now look at specific cell pairs
neurons_use = [20, 45];
sp_bool = arrayfun(@(a) cell_nos == a, neurons_use, ...
    'UniformOutput', false);
Tij = [sp_times(sp_bool{1}); sp_times(sp_bool{2})]/1000;
Gij = [ones(sum(sp_bool{1}), 1); 2*ones(sum(sp_bool{2}), 1)];
[ccg_ij, tR] = CCG(Tij, Gij, 'binsize', 1/SampleRate, ...
    'duration', duration, 'Fs', 1/SampleRate);

%% Calculate time to closest spike for all spikes in first train to second
% This takes FOREVER! Need to optimize somehow...parfor maybe?
t1 = Tij(Gij == 1); t2 = Tij(Gij == 2);
tclosest = nan(length(t1),1);
tic; 
disp('Calculating time to closest spike in second train to each spike in first spike train')
p = ProgressBar(100/1); 
update_inc = round(length(t1)/(100/1));
for i = 1:length(t1)
    tclosest(i) = t2(findclosest(t1(i), t2)); 
    if round(i/update_inc) == (i/update_inc)
        p.progress; 
    end 
end
p.stop; 
toc

tdiff = tclosest - t1;
%% First, plot CCG and time-to-closest-spike histogram
figure('Position', [1055 631 1587 1152]); 
subplot(2,1,1); 
H = histogram((tclosest - t1)*1000, ...
    ([tR; tR(end) + min(diff(tR))] - min(diff(tR))/2)*1000);
subplot(2,1,2); 
B = bar(tR*1000, squeeze(ccg_ij(:,1,2)));
B.BarWidth=1;
linkaxes(cat(1,subplot(2,1,1), subplot(2,1,2)))
acomb = cat(1, subplot(2,1,1), subplot(2,1,2));
titles = {'Time to closest spike', 'CCG'};
for i = 1:2
    set(acomb(i),'Box','off')
    xlabel(acomb(i), 'Lag (ms)')
    ylabel(acomb(i), 'Count')
    title(acomb(i), titles{i})
end

%% Now get the CCG for any spikes in t1 that have their closest spike
% within the limits below
peak_limits_ms = [-3.5, -1.2; -1.2, -0.25; -0.25, -0.05; -0.05, 0.1; 0.1, 1.4];
npeaks = size(peak_limits_ms);
ccg_ijp = [];
for j = 1:npeaks
    peak_bool = tdiff > peak_limits_ms(j, 1)/1000 & ...
        tdiff <= peak_limits_ms(j, 2)/1000;
    subplot(2,1,1); hold on
    Hpeak = histogram((tclosest(peak_bool) - t1(peak_bool))*1000, ...
        ([tR; tR(end) + min(diff(tR))] - min(diff(tR))/2)*1000);
%     legend(Hpeak, 'peak used below')
    
    Tijp = [t1(peak_bool); t2];
    Gijp = [ones(length(t1(peak_bool)),1); 2*ones(length(t2),1)];
    [ccg_temp, tR] = CCG(Tijp, Gijp, 'binsize', 1/SampleRate, ...
        'duration', duration, 'Fs', 1/SampleRate);
    ccg_ijp = [ccg_ijp squeeze(ccg_temp(:,1,2))]; 
end


%% Now plot this on top of CCG!!!
subplot(2,1,2); hold on;
Bpeak= bar(tR'*1000, ccg_ijp, 'stacked');
arrayfun(@(a) set(a, 'BarWidth', 1), Bpeak);
legend(Bpeak, 'only spikes from above peak')

%% Now get times for ALL spikes from RoyMaze1, not just maze part.
