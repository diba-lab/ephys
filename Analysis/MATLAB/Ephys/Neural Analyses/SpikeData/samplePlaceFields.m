toi=[hours(13)+minutes(15) hours(14)+minutes(45)];
% toi=[hours(15.8) hours(18)];
% toi=[hours(8.1) hours(12.55)];
folder='/data/EphysAnalysis/cluster/AG_day1/shank5/merged_2019-Dec-22__04-01-10_18-45-27/merged_2019-Dec-22__04-01-10_18-45-27crs-merged.GUI';
% folder='/data/EphysAnalysis/cluster/AG_day2/shank2/merged_2019-Dec-23__05-00-08_18-27-11/merged_2019-Dec-23__05-00-08_18-27-11crs-merged.GUI';
f=FigureFactory.instance;
[sa1, folder]=SpikeFactory.getSpykingCircusOutputFolder(folder,{'good'});
sa=sa1.getSpikeArrayWithAdjustedTimestamps;
tracksa=sa.getTimeInterval(toi);
tracksa.plot;f1=gcf;
if ~exist(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))),'file')
    f.save(fullfile(folder,'figures',sprintf('%s.png',matlab.lang.makeValidName(f1.Name))))
end
sa.plot;f1=gcf;
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

