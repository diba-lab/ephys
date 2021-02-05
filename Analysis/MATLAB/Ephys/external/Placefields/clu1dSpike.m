function [pmat]= clu1dSpike(fileinfo,tetrode,cluster,spike);
% function [pmat,skewmap,locmap]= clu1dSpike(fileinfo,tetrode,cluster,flag_plot_figure);
% a variance of clu1dsave that uses the spike files, instead of the res and
% clu...  could be faster...


figure(1)
clf

currentdir = pwd;
FileBase = [currentdir(1:end) '/' fileinfo.name '/' fileinfo.name];

if nargin < 4;
    load([FileBase '.spikeII.mat']);
end

Par =LoadPar([FileBase '.par']); % either par or xml file needed
SampleRate = Par.SampleRate;

videorate = 120;
xyt = fileinfo.xyt;
xr2 = fileinfo.new_xlim(1,:); xr1 = fileinfo.new_xlim(3,:);
tbegin = fileinfo.tbegin; tend = fileinfo.tend;
numofbins = round((tend-tbegin)/1e6*videorate);
withinrange = find(xyt(:,3)>=tbegin & xyt(:,3)<=tend);
tt = (xyt(:,3)-tbegin)/1e6*SampleRate;
xyt(:,3) = tt;
xytp=binpos(xyt(withinrange,:),numofbins);
tt = xytp(:,3);
timebinsize = .01;

if nargout ==0;
    placebins = 100;
else
    placebins = 200;
end

pmat = zeros(4,placebins);
xx = [1:100]';

for nn = 1:4;
    skewmap{nn} = [];
    locmap{nn} = [];
end

if tetrode==14;
    shankcluster = spike.qclu~=5;
else
    shankcluster = spike.shank==tetrode & spike.cluster==cluster;
end

tbin = linspace(0,spike.t(end),numofbins);
spktimes = spike.t(find(shankcluster));

nspk = hist(spktimes,xytp(:,3)); nspk(end)=0; nspk(1)=0; % find number of spikes per unit time.

inandout = LapIndices(fileinfo,0);
cc_nn = 'rrbb';

for nn = 4:-1:1;
    this_nn = inandout(1:2,find(inandout(4,:)==nn));
    if ~isempty(this_nn)
        all_within = [];
        for jj = 1:size(this_nn,2)
            within = [this_nn(1,jj):this_nn(2,jj)]';
            all_within = [all_within;within];
        end

        [xyto, nspko, rastero, edgeo, spkto] = SetXRange(xytp,nspk,this_nn);

%         if ~isempty(rastero)
%             addpoint = edgeo(1,end);
%         else
%             addpoint = 0;
%         end
        if nn<3
            addpoint = edgeo(1,end);
        else
            addpoint = 0;
        end

        subplot(4,2,nn+4)
        [pmap,omap]=PFClassic(xytp(all_within,:),nspk(all_within),.01,placebins);
        PFPlot(pmap/timebinsize,omap*timebinsize)
        [pmap,omap]=PF1D(xytp(all_within,:),.02,placebins);
        pmat(nn,:) = pmap;

        if mod(nn,2)
            subplot(4,2,1)
            plot(rastero(:,2),rastero(:,1) + addpoint,['.' cc_nn(nn)]); hold on
            plot(edgeo(2,:),edgeo(1,:)+ addpoint,'<k')
            plot(edgeo(3,:),edgeo(1,:)+ addpoint,'>k')
        else
            subplot(4,2,2)
            plot(rastero(:,2),rastero(:,1) + addpoint,['.' cc_nn(nn)]); hold on
            plot(edgeo(2,:),edgeo(1,:)+ addpoint,'<k')
            plot(edgeo(3,:),edgeo(1,:)+ addpoint,'>k')
        end
            
%         subplot(4,2,3)
%         [pmap,omap]=PFClassic(xyto,nspko',.01,placebins);
%         PFPlot(pmap/timebinsize,omap*timebinsize)
    end
end

        