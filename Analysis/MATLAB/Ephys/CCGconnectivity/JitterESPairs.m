% function [ExcPairs,InhPairs,GapPairs,numclu] = JitterESPairs(fileinfo,cellpairs,do_cat)
%% function [ExcPairs,InhPairs,GapPairs,numclu] = JitterESPairs(fileinfo,cellpairs,do_cat);
% take cellpairs defined through convolution and perform jitter analysis on
% them for non-parametric confirmation.

%% categories to consider
%% do_cat(1) = Excitatory Pairs
% % do_cat(2) = Inhibitory Pairs
% % do_cat(3) = Gap Pairs (i.e. 0 ms)

% if nargin<4;
%     do_cat = [1 1 1];
% end

currentdir = pwd;
FileBase = [currentdir '/' fileinfo.name '/' fileinfo.name];

Par =LoadPar([FileBase '.xml']); % either par or xml file needed
SampleRate = Par.SampleRate;

one_ms = SampleRate/1000;
if ~exist('timescale')
    timescale = 1;
end

BinSize = ceil(one_ms*timescale);
HalfBins = ceil(12.5*one_ms/BinSize);
currentdir = pwd;
directory = fileinfo.name;
FileBase = [currentdir '/' directory '/' directory];

load([FileBase '.spikeII.mat']);

INclu = unique(spike.aclu(spike.qclu==5))';
ncl = [];
for ii = INclu
    shank = spike.shank(find(spike.aclu==ii,1,'first'));
    cluster = spike.cluster(find(spike.aclu==ii,1,'first'));
    ncl = [ncl [shank;cluster;5]];
end

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

numclu = [maxp [zeros(4,size(ncl,2));ncl]];
for ii = 1:size(numclu,2);
    numclu(8,ii) = fileinfo.maxelec{numclu(5,ii)}(numclu(6,ii));
end

% tR = -HalfBins:HalfBins;
tR = 1000*(-HalfBins:HalfBins)*BinSize/SampleRate;
MonoWindow1=find((tR>=0.5)&(tR<=3.5));     % Mono Window 1ms ~3.5ms
MonoWindow2=find((tR>=-3.5)&(tR<=-0.5));
MonoWindow3=find((tR>-0.5)&(tR<0.5));
% tt=0;
nprint = 50;
PutativeExc = cellpairs.ExcPairs;
PutativeInh = cellpairs.InhPairs;
PutativeGap = cellpairs.GapPairs;
if ~exist('ExcPairs')
    ExcPairs=[];
end
if ~isempty(PutativeExc) & do_cat(1)
    skip =  PutativeExc(3,:)==PutativeExc(6,:)&PutativeExc(10,:)==PutativeExc(11,:); % proceed only if cells are not on same electrode
    PutativeExc = PutativeExc(:,~skip);
    fprintf(['\n E' num2str(size(PutativeExc,2)) ' ']) % write updates on progress
    print_ii = round(linspace(1,size(PutativeExc,2),nprint)); % designed for indicating progress
    print_ii = print_ii(2:end);
    if ~isempty(ExcPairs)
        ii_start = find(PutativeExc(1,:)==ExcPairs(1,end) & PutativeExc(2,:)==ExcPairs(2,end))+1;
    else
        ii_start = 1;
    end
% ii_start = 306;
    for ii = ii_start:size(PutativeExc,2)  %  continue in the loop
        if ismember(ii,print_ii)
            fprintf([num2str(ii) '.'])
        end
        ii_keeper = PutativeExc([1 2],ii);
        keeper1 = find(numclu(5,:)==cellpairs.numclu(5,ii_keeper(1)) &...
            numclu(6,:)==cellpairs.numclu(6,ii_keeper(1)));
        keeper2 = find(numclu(5,:)==cellpairs.numclu(5,ii_keeper(2)) &...
            numclu(6,:)==cellpairs.numclu(6,ii_keeper(2)));
        keeper = [keeper1 keeper2];
        if isempty(keeper);
            continue
        end
        keepclu = [];%  
        for cc = keeper;
            shank = numclu(5,cc);
            cluster = numclu(6,cc);
            cc_keep = find(spike.shank==shank & spike.cluster==cluster);
            keepclu = [keepclu; [cc_keep cc*ones(size(cc_keep))]];
        end
        res = [spike.t(keepclu(:,1)) keepclu(:,2)];
        
        
        [GSPE,~,pvalE]=CCG_jitter(res(res(:,2)==keeper1,1),res(res(:,2)==keeper2,1),SampleRate,ceil(BinSize),HalfBins,jscale,njitter,alpha,0);
        
        if any(GSPE(MonoWindow1)==1) 
            ExcPairs = [ExcPairs [keeper';numclu([5 6 7],keeper1);numclu([5 6 7],keeper2);max(pvalE(MonoWindow1));numclu(8,keeper1);numclu(8,keeper2)]];
        end
%         if any(GSPE(MonoWindow2)==1)
%             ExcPairs = [ExcPairs [keeper([2 1])'; numclu([5 6 7],keeper2);numclu([5 6 7],keeper1);max(pvalE(MonoWindow2));numclu(8,keeper2);numclu(8,keeper1)]];
%         end
    end
end
if ~exist('GapPairs')
    GapPairs=[];GapPairsZ = [];
end
if ~isempty(PutativeGap) & do_cat(3)    
    skip =  PutativeGap(3,:)==PutativeGap(6,:)&PutativeGap(10,:)==PutativeGap(11,:); % proceed only if cells are not on same electrode
    PutativeGap = PutativeGap(:,~skip);
    fprintf(['\n G' num2str(size(PutativeGap,2)) ' '])
    print_ii = round(linspace(1,size(PutativeGap,2),nprint));
    print_ii = print_ii(2:end);
    if ~isempty(GapPairs)
        ii_start = find(PutativeGap(1,:)==GapPairs(1,end) & PutativeGap(2,:)==GapPairs(2,end))+1;
    else
        ii_start = 1;
    end
    for ii = ii_start:size(PutativeGap,2);
        if ismember(ii,print_ii)
            fprintf(['.' num2str(ii)])
        end
        ii_keeper = PutativeGap([1 2],ii);
        keeper1 = find(numclu(5,:)==cellpairs.numclu(5,ii_keeper(1)) &...
            numclu(6,:)==cellpairs.numclu(6,ii_keeper(1)));
        keeper2 = find(numclu(5,:)==cellpairs.numclu(5,ii_keeper(2)) &...
            numclu(6,:)==cellpairs.numclu(6,ii_keeper(2)));
        keeper = [keeper1 keeper2];
        if isempty(keeper);
            continue
        end
        keepclu = [];%  
        for cc = keeper;
            shank = numclu(5,cc);
            cluster = numclu(6,cc);
            cc_keep = find(spike.shank==shank & spike.cluster==cluster);
            keepclu = [keepclu; [cc_keep cc*ones(size(cc_keep))]];
        end
        res = [spike.t(keepclu(:,1)) keepclu(:,2)];
        
        [GSPE,~,pvalE,~,~,~,LSPE]=CCG_jitter(res(res(:,2)==keeper1,1),res(res(:,2)==keeper2,1),SampleRate,ceil(BinSize),HalfBins,jscale,njitter,alpha,0);
        if any(LSPE(MonoWindow3)==1)
            GapPairsZ = [GapPairsZ [keeper';numclu([5 6 7],keeper1);numclu([5 6 7],keeper2);max(pvalE(MonoWindow3));numclu(8,keeper1);numclu(8,keeper2)]];
        end
        if any(GSPE(MonoWindow3)==1)
            GapPairs = [GapPairs [keeper';numclu([5 6 7],keeper1);numclu([5 6 7],keeper2);max(pvalE(MonoWindow3));numclu(8,keeper1);numclu(8,keeper2)]];
        end
    end
end
if ~exist('InhPairs')
    InhPairs=[];
end
if ~isempty(PutativeInh) & do_cat(2)
    skip =  PutativeInh(3,:)==PutativeInh(6,:)&PutativeInh(10,:)==PutativeInh(11,:); % proceed only if cells are not on same electrode
    PutativeInh = PutativeInh(:,~skip);
    %     PutativeInh = PutativeInh(:,PutativeInh(5,:)==5|PutativeInh(8,:)==5);
    fprintf(['\n I' num2str(size(PutativeInh,2)) ' '])
    print_ii = round(linspace(1,size(PutativeInh,2),nprint));
    print_ii = print_ii(2:end);
    if ~isempty(InhPairs)
        ii_start = find(PutativeInh(1,:)==InhPairs(1,end) & PutativeInh(2,:)==InhPairs(2,end))+1;
    else
        ii_start = 1;
    end
    for ii = ii_start:size(PutativeInh,2)
        if ismember(ii,print_ii)
            fprintf(['.' num2str(ii)])
        end
        ii_keeper = PutativeInh([1 2],ii);
        keeper1 = find(numclu(5,:)==cellpairs.numclu(5,ii_keeper(1)) &...
            numclu(6,:)==cellpairs.numclu(6,ii_keeper(1)));
        keeper2 = find(numclu(5,:)==cellpairs.numclu(5,ii_keeper(2)) &...
            numclu(6,:)==cellpairs.numclu(6,ii_keeper(2)));
        keeper = [keeper1 keeper2];
        if isempty(keeper);
            continue
        end
        keepclu = [];%  
        for cc = keeper;
            shank = numclu(5,cc);
            cluster = numclu(6,cc);
            cc_keep = find(spike.shank==shank & spike.cluster==cluster);
            keepclu = [keepclu; [cc_keep cc*ones(size(cc_keep))]];
        end
        res = [spike.t(keepclu(:,1)) keepclu(:,2)];
        
        [~,GSPI,~,pvalI]=CCG_jitter(res(res(:,2)==keeper1,1),res(res(:,2)==keeper2,1),SampleRate,ceil(BinSize),HalfBins,jscale,njitter,alpha,0);
        if any(GSPI(MonoWindow1)==1)
            InhPairs = [InhPairs [keeper';numclu([5 6 7],keeper1);numclu([5 6 7],keeper2);max(pvalI(MonoWindow1));numclu(8,keeper1);numclu(8,keeper2)]];
        end
%         if any(GSPI(MonoWindow2)==1)
%             InhPairs = [InhPairs [keeper([2 1])';numclu([5 6 7],keeper2);numclu([5 6 7],keeper1);max(pvalI(MonoWindow2));numclu(8,keeper2);numclu(8,keeper1)]];
%         end
    end
end

