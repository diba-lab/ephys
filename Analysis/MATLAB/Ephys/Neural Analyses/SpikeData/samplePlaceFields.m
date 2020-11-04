% toi=[hours(15.8) hours(18)];
% toi=[hours(8.1) hours(12.55)];
f=FigureFactory.instance;
sf=SpikeFactory.instance;
t_all=readtable('clusters.txt','Delimiter',',');
animal='AG';
day=1;
shanks=1:6;
idx_animal=ismember(t_all.animal,animal);
idx_day=ismember(t_all.day,day);
idx_shank=ismember(t_all.shank,shanks);
idx_all=idx_animal&idx_day&idx_shank;
folders=t_all.path(idx_all,:);
clear sa sa_adj
for ishank=shanks
    folder=folders{ishank};
    [sa1, folder]=sf.getSpykingCircusOutputFolder(folder);
    sa1=sa1.setShank(ishank);
    try
        sa_adj=sa_adj+sa1.getSpikeArrayWithAdjustedTimestamps;
        sa=sa+sa1;
    catch
        sa_adj=sa1.getSpikeArrayWithAdjustedTimestamps;
        sa=sa1;
    end
end
% idx_out=ismember(t_all.info,'out');
% folders=t_all.path(idx_out,:);
% sa.saveNeuroscopeFiles(folders{:})
time1=hours(13)+minutes(30);
toi=[time1 time1+seconds(5)]-minutes(1);
tracksa=sa_adj.getTimeInterval(toi);

tracksa.plot;f1=gcf;
t_lfp=readtable('LFPfiles.txt','Delimiter',',');
idx_animal=ismember(t_lfp.animal,animal);
idx_day=ismember(t_lfp.day,day);
idx_all=idx_animal&idx_day;
filepath=t_lfp.Filepath{idx_all};
sdd=StateDetectionData(filepath);
ch=sdd.getLFP(1,1);
ch_short=ch.getTimeWindowForAbsoluteTime(toi);
ax=gca;
ax.Position(4)=.7;
ticd=ch_short.getTimeIntervalCombined;
t=seconds(ticd.getTimePointsInSec)+ticd.getStartTime;


% bc=BuzcodeFactory.getBuzcode(filepath);
% ripple=bc.calculateSWR;
% [rippletimes]=ripple.getRipplesInAbsoluteTime(toi);

ax_ripple=axes('Units','normalized');p1=ax.Position;ax_ripple.Visible='off';
ax_ripple.Position=[p1(1) p1(2)+p1(4) p1(3) .05];
ch_shortBP=ch_short.getBandpassFiltered([120 250]);
hold on; ch_shortBP.plot();
% plot(rippletimes,0,'*');


ax_raw=axes('Units','normalized');p2=ax_ripple.Position;
ax_raw.Position=[p2(1) p2(2)+p2(4) p2(3) .05];
ch_short.plot;
ax_raw.Visible='off';
ch_shortBP=ch_short.getBandpassFiltered([4 12]);
hold on; ch_shortBP.plot('LineWidth',2,'Color','k');

if ~exist(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))),'file')
    f.save(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))))
end
sa_adj.plot;f1=gcf;
if ~exist(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))),'file')
    f.save(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))))
end
tracksa.saveObject(folder);
trackSus=tracksa.getSpikeUnits;
ol=OptiLoader.instance(0);
olc=ol.getOptiFilesCombined;
mld=olc.getMergedLocationData;
mldtrack=mld.getTimeWindow(toi);
% fname='Track Unit Place Fields';try close(fname);catch, end
% f2=figure('Units','normalized','Position',[0.5 0 .5 1],'Name',fname);
cfg.toi=toi;
cfg.folder=folder;
for isu=1:numel(trackSus)
    su=trackSus(isu);
    plotUnitTrack(su,mldtrack,cfg)
end
% try close('2dplot');catch, end;figure('Name','2dplot');mldtrack.plot
% mldtrack.plot3D
% mldtrack.plotSpikes3D(trackSus)
% mldtrack.plotSpikes(trackSus)

