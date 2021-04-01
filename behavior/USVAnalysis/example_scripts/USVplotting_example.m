%% Example script to analyze USV data.
% Steps to run after analyzing a session in DeepSqueak and screening the
% calls.
%% Step 0: Load data in
full_path_to_file = 'C:\Users\nkinsky\Documents\Working\Trace_FC\Pilot1\Rat705\2021_03_09_habituation\sleepbox\DetectionsT0000003 Mar-29-2021 12_35 PM.mat';

load(full_path_to_file, 'Calls');
% TODO: select files from UI.
%% Step 1: Extract calls from DeepSqueak "Calls" table variable

[times, freq_mean] = extract_calls(Calls);

%% Step 2: Separate calls

