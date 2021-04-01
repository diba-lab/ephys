%% Example script to analyze USV data.
% Steps to run after analyzing a session in DeepSqueak and screening the
% calls.
%% Step 0: Specify parameters for file to plot
full_path_to_file = 'C:\Users\nkinsky\Documents\Working\Trace_FC\Pilot1\Rat705\2021_03_09_habituation\sleepbox\Detections\T0000003 Mar-29-2021 12_35 PM.mat';
rat_name = '705';
session = 'Habituation - pre';

%% Step 0.5: Load data in
load(full_path_to_file, 'Calls');
% TODO: select files from UI.
%% Step 1: Extract calls from DeepSqueak "Calls" table variable

[times, freq_mean] = extract_calls(Calls);

%% Step 2: Separate calls

[calls_sep, high_bool, threshold] = separate_calls(freq_mean, times);

%% Step 3: Check visually to make sure threshold from step 2 looks good.
disp('Make sure to check threshold in histogram. Does it look good?')
disp('line should NOT go through a peak of the distribution')

%% Step 4: Bar plot of # High USVs vs # Low USVs

% First get # of high and low calls
ncalls_high = size(calls_sep.high.mean_freq, 1);
ncalls_low = size(calls_sep.low.mean_freq, 1);

% now plot
figure 
bar([1, 2], [ncalls_low, ncalls_high])
set(gca, 'XTickLabels', {['Low (<' num2str(threshold) 'kHz)'], ...
    ['High (>' num2str(threshold) 'kHz)']})
xlabel('USV type')
ylabel('# Calls')

box off  % make plot pretty

%% Step 5: Plot boxplot of call frequencies & lengths ON THE SAME FIGURE!

% Set up figure
figure

% Plot frequency distribution
subplot(1,2,1)
boxplot(freq_mean)

% label stuff (look above for hints!)

% plot time distribution
call_durations = times(:,2) - times(:,1);
subplot(1,2,2)
boxplot(call_durations)

% label stuff
set(gca, 'XTickLabels', '')


%% Other things to do
% A) align to video tracking data to see behavior when calls occur
