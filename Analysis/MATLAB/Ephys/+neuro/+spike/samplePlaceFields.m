% toi=[hours(15.8) hours(18)];
% toi=[hours(8.1) hours(12.55)];
f=FigureFactory.instance;
sf=SpikeFactory.instance;
t_all=readtable('clusters.txt','Delimiter',',');
animal='AG';
day=1;
shanks=1:6;
locations={'CA1','CA3'};
idx_animal=ismember(t_all.animal,animal);
idx_day=ismember(t_all.day,day);
idx_shank=ismember(t_all.shank,shanks);
idx_location=ismember(t_all.location,locations);
idx_all=idx_animal&idx_day&idx_shank;
folders=t_all.path(idx_all,:);
clear sa sa_adj
for ishank=shanks
    folder=folders{ishank};
    [sa1, folder]=sf.getSpykingCircusOutputFolder(folder);
    sa1=sa1.setShank(ishank);
    sa1=sa1.setLocation(t_all.location(ishank));
    try
%         sa_adj=sa_adj+sa1.getSpikeArrayWithAdjustedTimestamps;
        sa=sa+sa1;
    catch
%         sa_adj=sa1.getSpikeArrayWithAdjustedTimestamps;
        sa=sa1;
    end
end
%%
% idx_out=ismember(t_all.info,'out');
% folders=t_all.path(idx_out,:);
% sa.saveNeuroscopeFiles(folders{:})
colors=linspecer(3,'qualitative');
ticd=sa.TimeIntervalCombined;
time0=ticd.getRealTimeFor(seconds(minutes(27)+seconds(14))*ticd.getSampleRate);
time0=ticd.getRealTimeFor(seconds(minutes(524)+seconds(18))*ticd.getSampleRate);
time0=ticd.getRealTimeFor(seconds(minutes(470)+seconds(7))*ticd.getSampleRate);
time0=ticd.getRealTimeFor(seconds(minutes(500)+seconds(9))*ticd.getSampleRate);
time0=ticd.getRealTimeFor(seconds(minutes(509)+seconds(43.5))*ticd.getSampleRate);
time1=hours(13)+minutes(29)+seconds(0);
time1=hours(13)+minutes(29)+seconds(0);
time1=hours(13)+minutes(3)+seconds(9);
% time1=hours(13)+minutes(19)+seconds(0);
toi=[time0 time0+seconds(10)];
tracksa=sa.getTimeInterval(toi);

t_lfp=readtable('LFPfiles.txt','Delimiter',',');
idx_animal=ismember(t_lfp.animal,animal);
idx_day=ismember(t_lfp.day,day);
idx_all=idx_animal&idx_day;
filepath=t_lfp.Filepath{idx_all};
sdd=StateDetectionData(filepath);

ch1=sdd.getLFP(1,1);
ch1_short=ch1.getTimeWindowForAbsoluteTime(toi);

tfm=ch1_short.getTimeFrequencyMap(TimeFrequencyWavelet([8]));

tracksa_s=tracksa.sort({'location','ch','group','sh'});
tracksa_s.plot(tfm);f1=gcf;
ax=gca;
ax.Position(4)=.7;
ticd=ch1_short.getTimeIntervalCombined;
t=ticd.getTimePoints+ticd.getStartTime;


bc=BuzcodeFactory.getBuzcode(filepath);
ripple=bc.calculateSWR;
[rippletimes]=ripple.getRipplesInAbsoluteTime(toi);

% ax_ripple=axes('Units','normalized');p1=ax.Position;ax_ripple.Visible='off';
% ax_ripple.Position=[p1(1) p1(2)+p1(4) p1(3) .1];
% ax_ripple.YLim=[-500 500];
% ch_shortBP=ch_short.getBandpassFiltered([120 250]);
% hold on; ch_shortBP.plot('LineWidth',2);


ax_raw_ca1=axes('Units','normalized');p2=ax.Position;hold on;
ax_raw_ca1.Position=[p2(1) p2(2)+p2(4) p2(3) .1];
ch1_short.plot('LineWidth',1,'Color',colors(1,:));
% ax_raw_ca1.Visible='off';
% ax_raw_ca1.YLim=[-6000 6000];
ax_raw_ca1.XLim=ax.XLim;
if ~isempty(rippletimes),plot(rippletimes,max(ax_raw_ca1.YLim),'p',...
        'MarkerFaceColor',colors(3,:),'MarkerEdgeColor',colors(3,:),'MarkerSize',10);end

ch1_shortBP=ch1_short.getBandpassFiltered([4 12]);
hold on; ch1_shortBP.plot('LineWidth',2,'Color','k');
ax_raw_ca3=axes('Units','normalized');p2=ax_raw_ca1.Position;
ax_raw_ca3.Position=[p2(1) p2(2)+p2(4) p2(3) .1];hold on;
ch29=sdd.getLFP(29,1);
ch29_short=ch29.getTimeWindowForAbsoluteTime(toi);
ch29_short.plot('LineWidth',1,'Color',colors(2,:));
% ax_raw_ca3.Visible='off';
% ax_raw_ca3.YLim=ax_raw_ca1.YLim;hold on;
ax_raw_ca3.YTick=[-6000:1000:6000];
ax_raw_ca3.XLim=ax.XLim;

FigureFactory.instance.save(matlab.lang.makeValidName(f1.Name));
%%
if ~exist(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))),'file')
    f.save(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))))
end
sa_adj.plot;f1=gcf;
if ~exist(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))),'file')
    f.save(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))))
end
tracksa.saveObject(folder);
trackSus=tracksa.getSpikeUnits;
ol=OptiLoader.instance();
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

