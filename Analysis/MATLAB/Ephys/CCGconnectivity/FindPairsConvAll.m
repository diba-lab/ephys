function [ExcPairs,InhPairs,GapPairs,numclu] = FindPairsConvAll(fileinfo, session_name, SampleRate, stable_only)

% find excitatory and inhibitory cell pairs using all spikes from each unit
% % numclu now contains ID's for all the clustered cells
% % 1st to 4th rows are location of peak firing for each of 4 conditions (zero for interneurons)
% % 5th row is shank
% % 6th row is cluster
% % 7th row is cluster type
% % 8th row is the electrode with maximum amplitude for that Spike waveform (from the spk files)

% Only include interneurons stable across the entire session by default!
if nargin < 4
    stable_only = true;
end

load(fileinfo, 'spikes');
bz_spikes = Hiro_to_bz(spikes.(session_name), session_name);
% currentdir = pwd;
% FileBase = [currentdir '/' fileinfo.name '/' fileinfo.name];
% 
% Par =LoadPar([FileBase '.xml']); % either par or xml file needed
% EegRate = Par.lfpSampleRate; % sampling rate of eeg file
% SampleRate = Par.SampleRate;

alpha = .05;

jscale = 5; % units of ms
% njitter = 200; % # of times to jitter

% currentdir = pwd; 
% directory = fileinfo.name;
% FileBase = [currentdir '/' directory '/' directory];
% 
% load([FileBase '.spikeII.mat']);

if ~stable_only
    int_bool = ismember(bz_spikes.quality, 8);  % find only inhibitory clusters
elseif stable_only
    int_bool = ismember(bz_spikes.quality, 8) & bz_spikes.stability == 1;  % find only stable inhibitory clusters
end
ncl = [bz_spikes.shankID(int_bool); bz_spikes.UID(int_bool);
    bz_spikes.quality(int_bool)];

% now add in excitatory neurons!
if ~stable_only
    exc_bool = ismember(bz_spikes.quality, [1 2 3]);  % find only inhibitory clusters
elseif stable_only
    exc_bool = ismember(bz_spikes.quality, [1 2 3]) & bz_spikes.stability == 1;  % find only stable inhibitory clusters
end
ncl = [ncl [bz_spikes.shankID(exc_bool); bz_spikes.UID(exc_bool);
    bz_spikes.quality(exc_bool)]];


% lookfor = unique(spike.aclu(spike.qclu==5))';  % find only inhibitory clusters
% ncl = [];
% for ii = lookfor
%     shank = spike.shank(find(spike.aclu==ii,1,'first'));
%     cluster = spike.cluster(find(spike.aclu==ii,1,'first'));
%     ncl = [ncl [shank;cluster;5]];
% end

%% ncl, by design, contains 
%% 1st row shank
%% 2nd row cluster
%% 3rd row cluster type

% if isfield(fileinfo,'maxp')
%     maxp = fileinfo.maxp;
% else
maxp = []; % lookfor = unique(spike.aclu(ismember(spike.qclu,[1 2 4 8 9])))';
%     for ii = lookfor
%         ii_first = find(spike.aclu==ii,1,'first');
%         shank = spike.shank(ii_first);
%         cluster = spike.cluster(ii_first);
%         qclu = spike.qclu(ii_first);
%         ncl = [ncl [shank;cluster;qclu]];
%     end
% % end

numclu = [zeros(4, size(ncl,2)); ncl];
% numclu = [maxp [zeros(4,size(ncl,2));ncl]];  % add excitatory cells from maxp as well as 4 rows of zero to ncl

% I don't have this data in Hiro's data so make it up for now.
for j = 1:size(numclu,2)
    shank = numclu(5,j);
    numclu(8,j) = randi([1 8]) + (shank - 1)*8;
end
    

% for ii = 1:size(numclu,2);
%     numclu(8,ii) = fileinfo.maxelec{numclu(5,ii)}(numclu(6,ii));
% end
keepclu = [];
ExcPairs=[];InhPairs=[];GapPairs=[];
if ~isempty(numclu)
    for cc = 1:size(numclu,2)
        shank = numclu(5,cc);            
        cluster = numclu(6,cc);
        cc_keep = find(bz_spikes.shankID==shank & bz_spikes.cluID==cluster); 
        keepclu = [keepclu; [cc_keep cc*ones(size(cc_keep)) shank*ones(size(cc_keep))]];
        %         keepclu = 1st column all the spikes for cell1
        %                 = 2nd column an identification # for each cell
        %                   = 3rd column the shank that cell1 is from
    end
end
%

% According to PlotConnectedCells.m, this is what the final output should
% be! Variables should get dumped into cellpairs.ExcPairs, etc.
% 1st row = cell1 id
% 2nd row = cell2 id
% 3rd row = shank1
% 4th row = cluster1
% 5th row = cell1 type
% 6th row = shank2
% 7th row = cluster2
% 8th row = cell2 type
% 9th row = p-value
% 12th row = whether EP, IP or GP (1 2 or 3)

if ~isempty(keepclu)
    keepclu = sortrows(keepclu); % sort in order of increasing spike index (res)
    res = sortrows([spike.t(keepclu(:,1)) keepclu(:,[2 3])]);  % translate index into spike time
    [ExcPairs,InhPairs,GapPairs] = EranConv_group(res(:,1),res(:,2),unique(res(:,2)),SampleRate,jscale,alpha, res(:,3));
    if ~isempty(ExcPairs)  % add numclu information and reorder
        ExcPairs = [ExcPairs;numclu([5 6 7 8],ExcPairs(1,:))];
        ExcPairs = [ExcPairs([1 2 4 5 6],:);numclu([5 6 7],ExcPairs(2,:));ExcPairs(3,:);ExcPairs(7,:);numclu(8,ExcPairs(2,:))];
    end
    if ~isempty(InhPairs)
        InhPairs = [InhPairs;numclu([5 6 7 8],InhPairs(1,:))];
        InhPairs = [InhPairs([1 2 4 5 6],:);numclu([5 6 7],InhPairs(2,:));InhPairs(3,:);InhPairs(7,:);numclu(8,InhPairs(2,:))];
    end
    if ~isempty(GapPairs)
        GapPairs = [GapPairs;numclu([5 6 7 8],GapPairs(1,:))];
        GapPairs = [GapPairs([1 2 4 5 6],:);numclu([5 6 7],GapPairs(2,:));GapPairs(3,:);GapPairs(7,:);numclu(8,GapPairs(2,:))];
    end
    
end
end

