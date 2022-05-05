% load cell metrics
basenames = {'MergedRaw','MergedRaw','MergedRaw'};
basepaths = {'/data2/gdrive/ephys/clustering/AG_2020-01-05_SD/shank2','/data2/gdrive/ephys/clustering/AG_2020-01-05_SD/shank3','/data2/gdrive/ephys/clustering/AG_2020-01-05_SD/shank4'};
cell_metrics = loadCellMetricsBatch('basepaths',basepaths,'basenames',basenames);
% cell_metrics = CellExplorer('metrics',cell_metrics);
%%
types={'Pyramidal Cell','Narrow Interneuron','Wide Interneuron'};
types_short={'PYR','Narrow INT','Wide INt'};
numberofunits=[ 93, 65, 18];
% connections={'Pyramidal Cell','Wide Interneuron';
%     'Pyramidal Cell','Narrow Interneuron';
%     'Pyramidal Cell','Pyramidal Cell';
%     };

combunits=allcomb(numberofunits,numberofunits);
comcals=reshape(round(combunits(:,1).*combunits(:,2)/2),[3 3])';

connections=allcomb(types,types);
type=cell_metrics.putativeCellType;
excon=cell_metrics.putativeConnections.excitatory;
for icon=1:size(connections,1)
    from=connections{icon,1};
    from_id=find(ismember(type,from));
    to=connections{icon,2};
    to_id=find(ismember(type,to));
    comb=allcomb(from_id,to_id);
    number_of_connections(icon)=sum(ismember(excon,comb,'rows'));
end
cons=reshape(number_of_connections,[3 3])';
figure(1);
calcd=cons./comcals*100;
imagesc(calcd);
cb=colorbar('Location', 'southoutside');
cb.Label.String='% of putative connections';
% colormap('copper')
ylabel('From');
xlabel('To');
ax=gca;
ax.YTick=1:numel(types);
ax.YTickLabel=types_short;
ax.XTick=1:numel(types);
ax.XTickLabel=types_short;
for irow=1:size(cons,1)
    for icol=1:size(cons,2)
        text(irow,icol,sprintf('%.2f\n(%d/%d)',calcd(icol,irow),cons(icol,irow),comcals(icol,irow)),'HorizontalAlignment','center')
    end
end
title('Putative monosynaptic excitatory connections')
ff=logistics.FigureFactory.instance('.');
ff.save('CA3');