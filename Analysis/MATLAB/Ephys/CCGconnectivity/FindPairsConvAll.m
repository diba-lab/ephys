function [ExcPairs,InhPairs,GapPairs,numclu] = FindPairsConvAll(fileinfo);

% find excitatory and inhibitory cell pairs using all spikes from each unit
% % numclu now contains ID's for all the clustered cells
% % 1st to 4th rows are location of peak firing for each of 4 conditions (zero for interneurons)
% % 5th row is shank
% % 6th row is cluster
% % 7th row is cluster type
% % 8th row is the electrode with maximum amplitude for that Spike waveform (from the spk files)


currentdir = pwd;
FileBase = [currentdir '/' fileinfo.name '/' fileinfo.name];

Par =LoadPar([FileBase '.xml']); % either par or xml file needed
EegRate = Par.lfpSampleRate; % sampling rate of eeg file
SampleRate = Par.SampleRate;

alpha = .05;

jscale = 5; % units of ms
% njitter = 200; % # of times to jitter

currentdir = pwd; 
directory = fileinfo.name;
FileBase = [currentdir '/' directory '/' directory];

load([FileBase '.spikeII.mat']);

lookfor = unique(spike.aclu(spike.qclu==5))';  % find only inhibitory clusters
ncl = [];
for ii = lookfor
    shank = spike.shank(find(spike.aclu==ii,1,'first'));
    cluster = spike.cluster(find(spike.aclu==ii,1,'first'));
    ncl = [ncl [shank;cluster;5]];
end
%% ncl, by design, contains 
%% 1st row shank
%% 2nd row cluster
%% 3rd row cluster type

% if isfield(fileinfo,'maxp')
%     maxp = fileinfo.maxp;
% else
    maxp = [];lookfor = unique(spike.aclu(ismember(spike.qclu,[1 2 4 8 9])))';
    for ii = lookfor
        ii_first = find(spike.aclu==ii,1,'first');
        shank = spike.shank(ii_first);
        cluster = spike.cluster(ii_first);
        qclu = spike.qclu(ii_first);
        ncl = [ncl [shank;cluster;qclu]];
    end
% end

numclu = [maxp [zeros(4,size(ncl,2));ncl]];  % add excitatory cells from maxp as well as 4 rows of zero to ncl
for ii = 1:size(numclu,2);
    numclu(8,ii) = fileinfo.maxelec{numclu(5,ii)}(numclu(6,ii));
end
keepclu = [];
ExcPairs=[];InhPairs=[];GapPairs=[];
if ~isempty(numclu)
    for cc = 1:size(numclu,2)
        shank = numclu(5,cc);            
        cluster = numclu(6,cc);
        cc_keep = find(spike.shank==shank & spike.cluster==cluster); 
        keepclu = [keepclu; [cc_keep cc*ones(size(cc_keep)) shank*ones(size(cc_keep))]];
        %         keepclu = 1st column all the spikes for cell1
        %                 = 2nd column an identification # for each cell
        %                   = 3rd column the shank that cell1 is from
    end
end
%

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

