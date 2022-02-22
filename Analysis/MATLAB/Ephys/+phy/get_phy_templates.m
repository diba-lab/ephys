function [template, ch_ids, best_ch] = get_phy_templates(clust_id, dir_use)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%
% IMPORTANT NOTE: You will need to grab the files "ReadNPY.m" and 
% "ReadNPYheader.m" from https://github.com/kwikteam/npy-matlab and add
% them to your path for this function to work.

if nargin < 2
    dir_use = pwd;
end

% First read in the data
spk_clust_id = readNPY(fullfile(dir_use, 'spike_clusters.npy'));
templates = readNPY(fullfile(dir_use, 'templates.npy'));
spk_templates = readNPY(fullfile(dir_use, 'spike_templates.npy'));
chan_map = readNPY(fullfile(dir_use, 'channel_map.npy'));
template_ind = readNPY(fullfile(dir_use, 'template_ind.npy'));
clust_inf = tdfread(fullfile(dir_use, 'cluster_info.tsv'));

% Now use the first spike from the cluster id to grab that cluster's
% template.
first_spike_id = find(clust_id == spk_clust_id, 1, 'first');
template_id = spk_templates(first_spike_id) + 1;  % add 1 to adjust from python to matlab numbering

% Last, grab the template for that that cluster and its channels
template = transpose(squeeze(templates(template_id, : , :)));
temp_ch_inds = template_ind(template_id, :) + 1;  % Get channel ids in CHANNEL MAP for cluster
ch_ids = nan(1, length(temp_ch_inds));
ch_ids(temp_ch_inds > 0) = chan_map(temp_ch_inds(temp_ch_inds > 0));
best_ch = clust_inf.ch(clust_inf.cluster_id == clust_id);


end

