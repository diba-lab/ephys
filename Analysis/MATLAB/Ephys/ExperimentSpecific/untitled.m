
%%
clear all
sdl=SDLoader_heavy.instance;
oerc=sdl.getRat_AG_Day01_SD;
oers=oerc.getOpenEphysRecords;
oer1=oers.get(1);
for ishank=6:6
    channels=oer1.getProbe.getShank(ishank).getSiteSpatialLayout.ChannelNumberComingOutPreAmp
    %     oerc.saveChannels(channels);
    oerc.mergeBlocksOfChannels(channels,'/data2/gdrive/ephys/AG/Day01_SD/combined')
end

% AG_Day01_SD=AG_Day01_SD.getDownSampled(1250,sdl.getActiveWorkspaceFile);
% dayx.OpenEphysRecordCombined.runStateDetection;

%%
clear all
sdl=SDLoader_light.instance;
dayx=sdl.getRat_AG_Day02_NSD;
% AG_Day02_NSD=AG_Day02_NSD.getDownSampled(1250,sdl.getActiveWorkspaceFile);
% dayx.OpenEphysRecordCombined.runStateDetection;
% dayx.plotStateDetection
%%
clear all
sdl=SDLoader_light.instance;
day=sdl.getRat_AG_Day03_SD;
oerc=day.OpenEphysRecordCombined;
prb=oerc.getProbe;
sl=prb.getShank(1:6).getSiteSpatialLayout;
channels=sort(sl.ChannelNumberComingOutPreAmp);
oerc.mergeBlocksOfChannels(channels,sdl.getActiveWorkspaceFolder)
%%

clear all
sdl=SDLoader_light.instance;
day=sdl.getRat_AG_Day04_NSD;
oerc=day.OpenEphysRecordCombined;
prb=oerc.getProbe;
sl=prb.getShank(1:6).getSiteSpatialLayout;
channels=sort(sl.ChannelNumberComingOutPreAmp);
oerc.mergeBlocksOfChannels(channels,sdl.getActiveWorkspaceFolder)
%%

clear all
sdl=SDLoader_light.instance;
AG_Day05_SD=sdl.getRat_AG_Day05_SD;
AG_Day05_SD=AG_Day05_SD.getDownSampled(1250,sdl.getActiveWorkspaceFile);
% AG_Day05_SD.OpenEphysRecordCombined.runStateDetection;
%%
clear all
sdl=SDLoader_light.instance;
AG_Day06_NSD=sdl.getRat_AG_Day06_NSD;
AG_Day06_NSD=AG_Day06_NSD.getDownSampled(1250,sdl.getActiveWorkspaceFile);
% AG_Day06_NSD.OpenEphysRecordCombined.runStateDetection;


%%
startTimes={...
        '2019-12-23 05:30:00.000',...
        '2019-12-23 08:15:00.000',...
        '2019-12-23 11:15:00.000',...
        '2019-12-23 13:20:00.000',...
        '2019-12-23 15:10:00.000',...
        '2019-12-23 16:40:00.000',...
    };
colorevents=othercolor('Reds8',4);
linspecer(5,'sequential');
colore=containers.Map({'Tap','Shake','Bedding','Food'},{colorevents(2,:),...
    colorevents(3,:),colorevents(4,:),[0 0 0]});

colorl=linspecer(5);
states=containers.Map([1 2 3 5],{'WAKE','QWAKE','NREM','REM'});
colors=containers.Map([0 1 2 3 5],{colorl(1,:),colorl(2,:),colorl(3,:),colorl(4,:),colorl(5,:)});
for isec=1:numel(startTimes)
    clearvars -except dayx startTimes states colors colore isec
    startTime=startTimes{isec};
    timeWindow(1)=datetime(startTime,...
        'InputFormat','uuuu-MM-dd HH:mm:ss.SSS');
    timeWindow(2)=timeWindow(1)+hours(1)+minutes(30)+seconds(0);
    oerc=dayx.OpenEphysRecordCombined;
    [sections theOer]=oerc.getTimeWindow(timeWindow);
    update=false;
    stateData=theOer.getStateDetectionData(update);
    
    tsStateData=stateData.getTimewindow(timeWindow);
    section=sections{1};
    chanSelected=section.getChannels('CH71');
    chanTheta=section.getChannels(['CH' num2str(stateData.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics.THchanID+1)]);
    chanSW=section.getChannels(['CH' num2str(stateData.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics.SWchanID+1)]);
    newtsStateData=linspace(tsStateData.Time(1),tsStateData.Time(end),numel(chanSelected.getTime));
    tsStateDataHighSampling=tsStateData.resample(newtsStateData,'zoh');
    keys=states.keys;
    keysPlotted=[];
    ivalid=1;
    for istate=1:states.Count
        key=keys{istate};
        aChan1=chanSelected.getTimePoints(tsStateDataHighSampling.Data==key);
        try
            powerSpectrumState{ivalid}=aChan1.getPSpectrum();ivalid=ivalid+1;
            keysPlotted=horzcat(keysPlotted,key);
        catch
        end
    end
    chanSelectedw=chanSelected.getWhitened();
    %     aTimeFrequencyMethod=TimeFrequencyWavelet(1:1:10,1,-1/2);
    aTimeFrequencyMethod=TimeFrequencyChronuxMtspecgramc(1:.1:30);
    %     aTimeFrequencyMethod=TimeFrequencySpectrogram(1:.1:10);
    tfmsel=chanSelectedw.getTimeFrequencyMap(aTimeFrequencyMethod);
    
    chanThetaw=chanTheta.getWhitened();
    tfmTheta=chanThetaw.getTimeFrequencyMap(aTimeFrequencyMethod);
    chanSWw=chanSW.getWhitened();
    tfmSW=chanSWw.getTimeFrequencyMap(aTimeFrequencyMethod);
    
    powerSpectrum=chanSelected.getPSpectrum();
    %%

end
% legend(startTimes)
% folder='/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG';
% saveas(gcf,fullfile(folder,sprintf('%s_power_%s-%s.png',aChan.getChannelName{1},datestr(timeWindow(1)),datestr(timeWindow(2)))))
