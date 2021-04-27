function [EP,IP,GP] = PlotConnectedCells(cellpairs,showcat,figplot,scalefactor)
% function [EP,IP,GP] =  PlotCells2(cellpairs);

if nargin<2;           % flag indicating whether these should be plotted
    showcat = [1 1 1]; %cat1 = excitatory;cat2 = inhibitory; cat3 = gap junctions;
end
if nargin < 3;
    figplot = 901;
end
if nargin <4;
    scalefactor = 1;
end

ncl = cellpairs.numclu;

allpairs = [];EP = [];IP=[];GP=[];

eset = [1 2 4 8 9];
iset = [5];
okset = [eset iset];

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
if ~isempty(cellpairs.GapPairs)
GP = cellpairs.GapPairs(1:11,:);
GP = [GP;3*ones(1,size(GP,2))];
%     keeper = find((ismember(GP(5,:),iset) & ismember(GP(8,:),qset))|(ismember(GP(5,:),qset) & ismember(GP(8,:),iset)));  % look only for I-involved gap junctions
%     keeper = find(ismember(GP(5,:),eset) & ismember(GP(8,:),eset));% look only for E gap junctions
    keeper = find(ismember(GP(5,:),okset) & ismember(GP(8,:),okset));% look only for at good units.
    GP = GP(:,keeper);  
    allpairs = [allpairs GP([1 2 12 9],:)];
    scaleGP = max(GP(9,:))/5;
    GP = sortrows(GP')';
end
if ~isempty(cellpairs.ExcPairs)
EP = cellpairs.ExcPairs(1:11,:);
EP = [EP;1*ones(1,size(EP,2))];
    keeper = find(ismember(EP(5,:),okset) & ismember(EP(8,:),okset));% look only for at good units.
%     keeper = find(EP(5,:)~=5 & EP(8,:)==5);% look only for E-I excitatory connections
%     keeper = find(EP(8,:)~=5 & EP(5,:)~=5);EP = EP(:,keeper);  % look only for E-E excitatory connections\
    EP = EP(:,keeper);  
    allpairs = [allpairs EP([1 2 12 9],:)];
    EP = sortrows(EP')';
    scaleEP = max(EP(9,:))/5;
end
% keeper = find(EP(8,:)==5 & EP(5,:)==5);GP = [GP EP(:,keeper)]; % add I-I excitory to "gap junctions"
if ~isempty(cellpairs.InhPairs)
IP = cellpairs.InhPairs(1:11,:);
IP = [IP;2*ones(1,size(IP,2))];
    keeper = find(ismember(IP(5,:),okset)  & ismember(IP(8,:),okset));% & IP(3,:)~=IP(6,:));  % can't be on same shank.
    IP = IP(:,keeper);               % look for I pre/postsynaptic for inhibitory connections
    allpairs = [allpairs IP([1 2 12 9],:)];
    IP = sortrows(IP')';
    scaleIP = max(IP(9,:))/5;
end

    
if max(showcat)
    
celltype = '^^^^o^^^^';
cellcolor = 'bbbbmbbbb';
cnxcolor = 'ckr';

CAcolor = [[0 .8 1];[.65 .16 .16];[0 0 0];[.8 1 .0];[.16 .16 .65];[.16 .65 .16]];

cellface = [[1 0 0];[1 0 0];[1 0 0];[1 0 0];[0 0 0];[1 0 0];[1 0 0];[1 0 0];[1 0 0]];

for ii = 1:length(cellpairs.CA)
    if (cellpairs.CA(ii)>50)
        cellpairs.CA(ii) = 5;
    end
end

% set(gcf,'Position',[325 55 800 550])

% if showcat(1)
% end
% if showcat(2)
% end
% if showcat(3)
% end
if isempty(allpairs)
    return
end
uniquecells = unique(allpairs(1:2,:))'; % which are the actual cells involved
delta = [-.02 0 .02];

%add shank and elec info
for ii = 1:length(uniquecells);
    uniquecells(2:4,ii) = ncl(5:7,uniquecells(1,ii)); % add shank and cluster info
    uniquecells(5,ii) = cellpairs.maxelec{ncl(5,uniquecells(1,ii))}(ncl(6,uniquecells(1,ii)));  % add position of max amplitude
end

xxca = 1:length(cellpairs.CA);
if length(unique(cellpairs.CA))>1 % more than one region
    firstca = cellpairs.CA(1);
    nonfirstca = find(cellpairs.CA~=firstca);
    xxca(nonfirstca) = xxca(nonfirstca) +1;
    nextca = find(ismember(uniquecells(2,:),nonfirstca));
    uniquecells(2,nextca) = uniquecells(2,nextca) +1;
end

    
shankmin = min(uniquecells(2,:));
shankmax = max(uniquecells(2,:));
elecmin = min(uniquecells(5,:));
elecmax = max(uniquecells(5,:));

% add offsets for figure;
offset = 0.3*[[0 0];[-1 1];[1 -1];[-1 -1];[1 1];[-1 0];[1 0];[0 1];[0 -1]];

figure(figplot)
clf

% 
for ii=1:size(uniquecells,2);
    ii_find = find(uniquecells(2,ii:end)==uniquecells(2,ii) & uniquecells(5,ii:end)==uniquecells(5,ii));
    jj = length(ii_find);
    uniquecells(2,ii) = uniquecells(2,ii)+offset(jj,1);
    uniquecells(5,ii) = uniquecells(5,ii)+offset(jj,2);
    plot(uniquecells(2,ii),uniquecells(5,ii),...
        [celltype(uniquecells(4,ii)) cellcolor(uniquecells(4,ii))],'MarkerFaceColor',cellcolor(uniquecells(4,ii)),'MarkerSize',15,'LineWidth',2);hold on
end
hold off

% first plot the cells with approprite shape and color 
for ii = 1:size(allpairs,2)  % one by one for each cellpair
    c1 = find(uniquecells(1,:)==allpairs(1,ii));
    c2 = find(uniquecells(1,:)==allpairs(2,ii));
    xx = [uniquecells(2,c1) uniquecells(2,c2)]; % set the appropriate x,y for the cell 1 & 2
    yy = [uniquecells(5,c1) uniquecells(5,c2)];
%     plot(xx(2)+delta(allpairs(3,ii)), yy(2),['*' cnxcolor(allpairs(3,ii))],'MarkerSize',8);
    if allpairs(3,ii)==1 & showcat(1)
        plot(xx+delta(allpairs(3,ii)),yy+delta(allpairs(3,ii)),cnxcolor(allpairs(3,ii)),'LineWidth',1);hold on
        phi = abs(atan(diff(yy+delta(allpairs(3,ii)))/diff(xx+delta(allpairs(3,ii)))));
        signxx = sign(diff(xx)); signyy = sign(diff(yy));
        plot(xx(2)-0.15*signxx*cos(phi), yy(2)-.15*signyy*sin(phi),['.' cnxcolor(allpairs(3,ii))],'MarkerSize',24);
%         plot(xx+delta(allpairs(3,ii)),yy,cnxcolor(allpairs(3,ii)),'LineWidth',allpairs(4,ii)/scaleEP);
%         plot(xx(1)+delta(allpairs(3,ii))+0.96*diff(xx), yy(1)+.96*diff(yy),['.' cnxcolor(allpairs(3,ii))],'MarkerSize',15);
    end
end
% first plot the cells with approprite shape and color 
for ii = 1:size(allpairs,2)  % one by one for each cellpair
    c1 = find(uniquecells(1,:)==allpairs(1,ii));
    c2 = find(uniquecells(1,:)==allpairs(2,ii));
    xx = [uniquecells(2,c1) uniquecells(2,c2)]; % set the appropriate x,y for the cell 1 & 2
    yy = [uniquecells(5,c1) uniquecells(5,c2)];
%     plot(xx(2)+delta(allpairs(3,ii)), yy(2),['*' cnxcolor(allpairs(3,ii))],'MarkerSize',8);
    if allpairs(3,ii)==2 & showcat(2)
        phi = abs(atan(diff(yy)/diff(xx+delta(allpairs(3,ii)))));
        signxx = sign(diff(xx)); signyy = sign(diff(yy));
        plot(xx+delta(allpairs(3,ii)),yy,cnxcolor(allpairs(3,ii)),'LineWidth',3);hold on
%         plot(xx+delta(allpairs(3,ii)),yy,cnxcolor(allpairs(3,ii)),'LineWidth',allpairs(4,ii)/scaleIP);
        plot(xx(2)-.15*signxx*cos(phi), yy(2)-.15*signyy*sin(phi),['.' cnxcolor(allpairs(3,ii))],'MarkerSize',28);
    end
end
% first plot the cells with approprite shape and color 
for ii = 1:size(allpairs,2)  % one by one for each cellpair
    c1 = find(uniquecells(1,:)==allpairs(1,ii));
    c2 = find(uniquecells(1,:)==allpairs(2,ii));
    xx = [uniquecells(2,c1) uniquecells(2,c2)]; % set the appropriate x,y for the cell 1 & 2
    yy = [uniquecells(5,c1) uniquecells(5,c2)];
%     plot(xx(2)+delta(allpairs(3,ii)), yy(2),['*' cnxcolor(allpairs(3,ii))],'MarkerSize',8);
    if allpairs(3,ii)==3 & showcat(3)
%         plot(xx+delta(allpairs(3,ii)),yy+delta(allpairs(3,ii)),cnxcolor(allpairs(3,ii)),'LineWidth',1);hold on
        plot(xx+delta(allpairs(3,ii)),yy,cnxcolor(allpairs(3,ii)),'LineWidth',1);
%         plot(xx+delta(allpairs(3,ii)),yy,cnxcolor(allpairs(3,ii)),'LineWidth',allpairs(4,ii)/scaleGP);
    end
end

for ii=1:size(uniquecells,2);
    ii_find = find(uniquecells(2,ii:end)==uniquecells(2,ii) & uniquecells(5,ii:end)==uniquecells(5,ii));
    jj = length(ii_find);
    uniquecells(2,ii) = uniquecells(2,ii)+offset(jj,1);
    uniquecells(5,ii) = uniquecells(5,ii)+offset(jj,2);
    plot(uniquecells(2,ii),uniquecells(5,ii),...
        [celltype(uniquecells(4,ii)) cellcolor(uniquecells(4,ii))],'MarkerFaceColor',cellcolor(uniquecells(4,ii)),'MarkerSize',15,'LineWidth',2);
end

for ca=unique(cellpairs.CA)
    ii_ca = xxca(find(cellpairs.CA==ca));
%     plot([min(ii_ca)-.5 max(ii_ca)+.5],(elecmin-.5)*[1 1],'Color',CAcolor(ca+1,:),...
%         'LineWidth',4);
%     text(min(ii_ca)+1.5,elecmin-1,['CA' num2str(ca) ' shanks' ],'Color',CAcolor(ca+1,:))    
    plot([min(ii_ca)-.5 max(ii_ca)+.5],(elecmin-.5)*[1 1],'Color',[.8 .8 .8],...
        'LineWidth',4);
    text(min(ii_ca)+1.5,elecmin-1,['CA' num2str(ca) ' shanks' ],'Color',[.8 .8 .8])
end
% plot([max(ii_ca)+.5 max(ii_ca)+.5],[(elecmin-.5) (elecmax+.5)],'--','Color',[.9 .9 .9],...
%         'LineWidth',4);

xlim([shankmin-.5 shankmax+.5])
ylim([elecmin-.5 elecmax+.5])
set(gca,'XTick',xxca,'YTick',elecmin:elecmax,'XTickLabel',shankmin:shankmax)
gpos = get(gcf,'Position');
% set(gcf,'Position',[gpos(1:2) (shankmax-shankmin)*135 (elecmax-elecmin)*95 ],'PaperOrientation', 'landscape','PaperType','A4')
set(gcf,'Position',[gpos(1:2) (shankmax-shankmin)*105 (elecmax-elecmin)*95 ])
hold off
end
% axis off
