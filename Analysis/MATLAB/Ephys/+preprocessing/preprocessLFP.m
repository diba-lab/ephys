sdl=SDLoader_heavy.instance;
folders={'/data2/gdrive/ephys/AG/Day01_SD',...
    '/data2/gdrive/ephys/AG/Day02_NSD',...
    '/data2/gdrive/ephys/AG/Day03_SD',...
    '/data2/gdrive/ephys/AG/Day04_NSD',...
    '/data2/gdrive/ephys/AF/Day01-SD',...
    '/data2/gdrive/ephys/AF/Day02-NSD'};
funcs={'getRat_AG_Day01_SD',...
    'getRat_AG_Day02_NSD',...
    'getRat_AG_Day03_SD',...
    'getRat_AG_Day04_NSD',...
    'getRat_AF_Day01_SD',...
    'getRat_AF_Day02_NSD',...
    };


downsample=false;
if downsample
    for iday= 1
        sdl=sdl.(funcs{iday});
        oerc=sdl.getActiveOpenEphysRecord;
        
        %% for spike detection save seperate shanks
        
        %% for oscillatory analyses select channels, downsample
        chSelOneShank=[18 6 29 2 24 22];
        combined=[chSelOneShank+32*3 chSelOneShank+32*2 chSelOneShank+32 ...
            chSelOneShank chSelOneShank+32*5 chSelOneShank+32*4];%
        list=dir([sdl.getActiveWorkspaceFile '/*Probe*']);
        probe=Probe(fullfile(list.folder,list.name));
        close;probe.plotProbeLayout(combined);
        oerc=oerc.setProbe(probe);
        filename=oerc.mergeBlocksOfChannels(combined,folders{iday});
        chantime=neuro.basic.ChannelTimeDataHard(filename);
        chantime_ds=chantime.getDownSampled(1250,sdl.getActiveWorkspaceFile);
        channel=1;
        SleepScoreMaster(chantime_ds.getFolder,...
            'SWChannels',channel,'ThetaChannels',channel,...
            'overwrite',false);
    end
    % OpenEphysRecordFactory.getOpenEphysRecord()
    SleepScoreMaster('/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day04_NSD/merged_2019-Dec-27__04-49-48_20-03-08',...
        'SWChannels',1,'ThetaChannels',1,...
        'overwrite',false);
else
    for iday= 6:6
        clearvars -except iday sdl folders funcs
        sdl=sdl.(funcs{iday});
        oerc=sdl.getActiveOpenEphysRecord;
        %% for spike detection save seperate shanks
        
        %% for oscillatory analyses select channels, downsample
        list=dir([sdl.getActiveWorkspaceFile '/*Probe*']);
        probe=Probe(fullfile(list.folder,list.name));
        close;probe.plotProbeLayout();
        oerc=oerc.setProbe(probe);
        lay=probe.getSiteSpatialLayout;
        shanks=unique(lay.ShankNumber(lay.isActive==1));
        for ishank=1:numel(shanks)
            shank=shanks(ishank);
            theshank=probe.getShank(shank);
            chans=theshank.getActiveChannels;
            filename=oerc.mergeBlocksOfChannels(chans,...
                fullfile(folders{iday},sprintf('shank%d',shank)));
        end
    end
end