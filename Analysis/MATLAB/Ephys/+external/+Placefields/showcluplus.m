function []= showcluplus(fileinfo,tetrode,cluster);

% this function will show the classic place fields for "FileBase" on the
% long and short track.  "tetrode" and "cluster" may be specified for
% additional specification. (tetrode can be a shank on the probe).

currentdir = pwd; 

FileBase = [currentdir(1:end) '/' fileinfo.name '/' fileinfo.name];
xyt = fileinfo.xyt;
xr2 = fileinfo.xr2; xr1 = fileinfo.xr1;
        % in xyt.mat we have saved variables "xyt", which are the location
        % vs. time, "chtstamp", which is the timestamp after which the
        % maze is switched from long to short, and "xr1","xr2","yr1","yr2"
        % which represent the x,and y coordinates for the two gates through
        % which the animal's running is to be plotted
tbegin = fileinfo.tbegin; tend = fileinfo.tend;
    % the beginnging and ending timestamp are obtained from the log file.
numofbins = round((tend-tbegin)/1e6*100);
withinrange = find(xyt(:,3)>=tbegin & xyt(:,3)<=tend);
xytp=binpos(xyt(withinrange,:),numofbins);  % we divide up the position vector into regular 10 ms bins
timebinsize = .01; % tbins in units of seconds;
% when the maze is changed from long to
% if isfield(fileinfo,'yr1')
%     yr1 = fileinfo.yr;
%     yind = find(xytp(:,2) > min(yr1) & xytp(:,2) < max(yr1));
%     xytp = xytp(yind,:);
% end
tchg = find(xytp(:,3) > fileinfo.chts,1,'first');    % short
iend = find(xytp(:,3) <= tend,1,'last');

if (nargin<2);
    tetrode = 1:4;
end

for tet = tetrode;
    
    clu = LoadClu([FileBase '.clu.' num2str(tet)]);
    res = Loadres([FileBase '.res.' num2str(tet)]);
    
    if nargin<3;
        cluster = [2:max(clu)];
    end
    
for jj = cluster;

    [spkt] = selectgroup(res,clu,jj);
    if isempty(spkt);
        'There are no spike times for this cluster!';
        return;
    end
    spkg = ones(size(spkt));
    
    spktimes = tbegin + spkt*1e6/32552.1;  % these spike times are converted to Neuralynx timestamps
    % which are in units of microseconds

    nspk = hist(spktimes,xytp(:,3)); nspk(end)=0; nspk(1)=0;% find number of spikes per unit time.

    nspk = velocityfilter(xytp,nspk,0.000108/2);

    [outgoing,incoming] = trackCross(xytp(tchg:iend,1),min(xr2),max(xr2),0);
    % gives you indices for when the rat crosses barriers at xr2
    % since we input xyt starting with tchg, we won't worry about it in
    % later steps
    outgoing = outgoing + tchg; incoming = incoming + tchg;
    % shift indices to reflect start time

    [xyto2, nspko2, rastero2, edgeo2, spkto2] = SetXRange(xytp,nspk,outgoing);
    % this function takes
    % the indices from trackCross, which are for outgoing or incoming
    % trajectories, and outputs xyt, nspk, rasters, and the effective
    % edges given by "outgoing".
    [xytin2, nspkin2, rasterin2, edgein2, spktin2] = SetXRange(xytp,nspk,incoming);
    
    if ~isempty(incoming)
    if incoming(1)<outgoing(1);
        shiftin = [incoming(1,:) iend];
        innew = [incoming(1,:);outgoing(1,:)];
        outnew =[outgoing(1,:);shiftin(2:end)];
    else
        shiftin = [outgoing(1,:) iend];
        innew = [incoming(1,:);shiftin(2:end)];
        outnew =[outgoing(1,:);incoming(1,:)];
    end

    [xyto2, nspko2, rastero2, unused, spkto2] = SetXRange(xytp,nspk,outnew);
    [xytin2, nspkin2, rasterin2, unused, spktin2] = SetXRange(xytp,nspk,innew);
    spkto2 = (spkto2-tbegin)*32552.1/1e6;  % convert form
    spktin2 = (spktin2-tbegin)*32552.1/1e6;
    % similarly this is done for incoming.
    
    end
    
    

    % ROUTINE IS NOW DONE FOR LONG MAZE
    [outgoing,incoming] = trackCross(xytp(1:tchg,1),min(xr1),max(xr1),0);
    [xyto, nspko, rastero, edgeo, spkto] = SetXRange(xytp,nspk,outgoing);
    [xytin, nspkin, rasterin, edgein, spktin] = SetXRange(xytp,nspk,incoming);
    
    if incoming(1)<outgoing(1);
        shiftin = [incoming(1,:) tchg];
        innew = [incoming(1,:);outgoing(1,:)];
        outnew =[outgoing(1,:);shiftin(2:end)];
    else
        shiftin = [outgoing(1,:) tchg];
        innew = [incoming(1,:);shiftin(2:end)];
        outnew =[outgoing(1,:);incoming(1,:)];
    end
    
    [xyto, nspko, rastero, unused, spkto] = SetXRange(xytp,nspk,outnew);
    [xytin, nspkin, rasterin, unused, spktin] = SetXRange(xytp,nspk,innew);
    spkto = (spkto-tbegin)*32552.1/1e6;
    spktin = (spktin-tbegin)*32552.1/1e6;
    %         % these functions include xyt and nspk which fall only within theta
    %         % periods defined by sts.
    %     [xyto2,nspko2] = SetTRange(xyto2,nspko2,sts);
    %     [xyto,nspko] = SetTRange(xyto,nspko,sts);
    %     [xytin2,nspkin2] = SetTRange(xytin2,nspkin2,sts);
    %     [xytin,nspkin] = SetTRange(xytin,nspkin,sts);

    %     figure(tet);

    figure(1); clf
    if ~isempty(rastero)
        addpoint = edgeo(1,end);
    else
        addpoint = 0;
    end

    if ~isempty(rastero2)
        subplot(3,2,1)
        plot(rastero2(:,2),rastero2(:,1) + addpoint,'.r'); hold on    
        plot(edgeo2(2,:),edgeo2(1,:)+ addpoint,'<k') 
        plot(edgeo2(3,:),edgeo2(1,:)+ addpoint,'>k')
        subplot(4,2,3)
        [pmap,omap]=PFClassic(xyto2,nspko2',0.01,100);
        PFPlot(pmap/timebinsize,omap*timebinsize)
    end
    if ~isempty(rastero)
        subplot(3,2,1)
        plot(rastero(:,2),rastero(:,1),'.b');hold on 
        plot(edgeo(2,:),edgeo(1,:),'<k')
        plot(edgeo(3,:),edgeo(1,:),'>k')
        set(gca,'XTickLabel',{})
        
        subplot(4,2,5)
        [pmap,omap]=PFClassic(xyto,nspko',0.01,100);
        PFPlot(pmap/timebinsize,omap*timebinsize)
    end
    subplot(3,2,1)
    ax = axis;
    wh = title([fileinfo.name ' shank ' num2str(tet) ' Cluster ' num2str(jj) ' RIGHT']);
    set(wh,'Interpreter','none')

    if ~isempty(rasterin)
        addpoint = edgein(1,end);
    else
        addpoint = 0;
    end
    if ~isempty(rasterin2)
        subplot(3,2,2)
        plot(rasterin2(:,2),rasterin2(:,1) + addpoint,'.r'); hold on    
        plot(edgein2(2,:),edgein2(1,:)+ addpoint,'>k') 
        plot(edgein2(3,:),edgein2(1,:)+ addpoint,'<k')

        subplot(4,2,4)
        [pmap,omap]=PFClassic(xytin2,nspkin2',0.01,100);
        PFPlot(pmap/timebinsize,omap*timebinsize)
    end
    if ~isempty(rasterin)
        subplot(3,2,2)
        plot(rasterin(:,2),rasterin(:,1),'.b');hold on 
        plot(edgein(2,:),edgein(1,:),'>k')
        plot(edgein(3,:),edgein(1,:),'<k')
        set(gca,'XTickLabel',{})
        
        subplot(4,2,6)
        [pmap,omap]=PFClassic(xytin,nspkin',0.01,100);
        PFPlot(pmap/timebinsize,omap*timebinsize)   
    end
    subplot(3,2,2)
    ax2 = axis;
    axis([0 1 0 max([ax(4) ax2(4)])]);
    subplot(3,2,1)
    axis([0 1 0 max([ax(4) ax2(4)])]);
    subplot(3,2,2)
%     legend('short','long',0)
    
    
    wh = title([fileinfo.name ' shank ' num2str(tet) ' Cluster ' num2str(jj) ' LEFT']);
    set(wh,'Interpreter','none')
  
    spkt2 = [spkto;spktin;spkto2;spktin2];
    spkg2 = [ones(length(spkto),1);2*ones(length(spktin),1);...
        3*ones(length(spkto2),1);4*ones(length(spktin2),1)];
    spkt3 = sort([spkto; spktin; spkto2; spktin2]);
    spkg3 = ones(length(spkt3),1);
    HalfBins = 100;
    BinSize = 32.552*2;
    [ccg, t] = CCG(spkt,spkg,BinSize,HalfBins);
    noise = sum(ccg(HalfBins:HalfBins+2))/ccg(end);
    
    subplot(4,1,4)
%     for nn = 1:4;
%         subplot(2,2,nn)
%         bar(t,squeeze(ccg(end:-1:1,nn,nn)),'k');
%         ax = axis;
%         axis([-20 20 0 ax(4)]);
%     end
    bar(t,squeeze(ccg(end:-1:1,1,1)),'k');
%     xlim([-100 100])
    axis tight
    if isfield(fileinfo,'cluq2')
        cluq2 = fileinfo.cluq2{tetrode}(cluster);
        title(['\bf Cluq = ' num2str(cluq2)]);
    end
end
    
    if numel(tetrode)>1;beep;end
end
end