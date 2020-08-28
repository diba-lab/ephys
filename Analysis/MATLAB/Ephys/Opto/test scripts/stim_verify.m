jsonFile = 'C:\Users\Nat\Documents\UM\Working\Opto\Rat613\Rat613Day2\Rat613pre_2020-08-03_05-57-16\experiment1\recording1\structure.oebin';
chan_map_file = 'C:\Users\Nat\Documents\UM\Working\Opto\Rat613\2x32MINT_chan_map_good.txt';
D = load_open_ephys_binary(jsonFile, 'continuous', 1, 'mmap');
evts = load_open_ephys_binary(jsonFile,'events',1);
SR = D.Header.sample_rate;

temp = importdata(chan_map_file, ',');
chan_map = temp.data;

% enter in stim vs no-stim shanks to look at here.
stim_channels = [7 8]; % shank 1
stim_shank = [1 1];
no_stim_channels = [15 16 23 24]; % shank 2 and shank 3.
no_stim_shank = [2 2 3 3];
chan_comb_mapped = chan_map(cat(2, stim_channels, no_stim_channels));
shanks_comb = cat(2, stim_shank, no_stim_shank);
nstim_chan = length(stim_channels);
nchan = length(chan_comb_mapped);
ds_freq = 1250;

%% downsample data - note that decimate function removes any spikes with its
% anti-aliasing - do not use that function here...
if SR/ds_freq ~= round(SR/ds_freq)
    error('downsample rate must be an integer divisor of acquisition rate')
end
tic; 
traces_ds = downsample(double(D.Data.Data(1).mapped(chan_comb_mapped,:))',...
    SR/ds_freq)'; 
toc
time_ds = double(D.Timestamps(1:(SR/ds_freq):end))'/SR;
%% band-pass channels 7 and 8, as well as 14 and 15? 
bp_limits = [300, ds_freq/2*0.99];
[B,A] = butter(4, bp_limits/(ds_freq/2));
traces_bp = nan(size(traces_ds));
for j = 1:nchan
    traces_bp(j,:) = filtfilt(B,A,traces_ds(j,:));
end

%% threshold to get MUA
mua_thresh = 2; % # stdevs below mean in bp trace for MUA activity...
trace_std = std(traces_bp, 1, 2);

mua_times = cell(1, nchan);
for j = 1:nchan
   below_thresh_bool = traces_bp(j,:) < -mua_thresh*trace_std(j); 
   mua_times{j} = time_ds(below_thresh_bool);
end


%% get TTL event times
TTLin = 2; % TTL port where opto-triggering was reported
test_time = 1; % time of light pulses used to test stim level.
test_end = 15*60; % stopped testing here...

evt_times = double(evts.Timestamps)/SR;
on_times = evt_times(evts.Data == TTLin);
off_times = evt_times(evts.Data == -TTLin);
test_stim_bool = (off_times - on_times) > 0.95*test_time & on_times < test_end;
on_test = on_times(test_stim_bool);
off_test = off_times(test_stim_bool);

%% generate peri-event rasters
bin_size = 0.1;
limits = [-1 2]; % time relative to on_stim to plot (e.g. [-1 2] = 1 sec before to 2 sec after.

PEhisto = cell(1, nchan); PEtimes = cell(1, nchan);
for j = 1:nchan
   PEtimes{j} = generate_PErasters(mua_times{j}, on_test, ...
       bin_size, limits);
end

%% Now plot everything
bin_size = 0.1;
hf = figure; set(gcf,'Position', [ 5, 70, 1460, 710]);
subplot_order = [1 4 2 5 3 6]; % Use this to plot two stim sessions on left, others on right.
title_stim = {'Stim', 'No Stim'};
for j = 1:nchan
   ax_use = subplot(2, 3, subplot_order(j));
   plotStimRasters(PEtimes{j}, [0 test_time], limits, ax_use, bin_size)
   title(ax_use, {['Shank ' num2str(shanks_comb(j)) ' - ' title_stim{(j > nstim_chan) + 1}],...
       ['MUA threshold = ' num2str(mua_thresh) ' std']})
end
