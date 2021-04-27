sdl=SDLoader_heavy.instance;
folders={'/data2/gdrive/ephys/AA/day01_SD',...
    '/data2/gdrive/ephys/AA/day02_NSD',...
    '/data2/gdrive/ephys/AA/day03_SD',...
    '/data2/gdrive/ephys/AA/day04_NSD',...
    };
funcs={'getRat_AA_Day01_SD',...
    'getRat_AA_Day02_NSD',...
    'getRat_AA_Day03_SD',...
    'getRat_AA_Day04_NSD'};


downsample=true;
if downsample
    for iday= 1:2
        oerc=sdl.(funcs{iday});
        %% for spike detection save seperate shanks
        
        %% for oscillatory analyses select channels, downsample
        probe=oerc.getProbe;
        combined=[probe.getShank(1).getActiveChannels; ...
            probe.getShank(2).getActiveChannels; ...
            probe.getShank(3).getActiveChannels; ...
            probe.getShank(4).getActiveChannels ];
        filename=oerc.mergeBlocksOfChannels(combined,folders{iday});
        chantime=ChannelTimeData(filename);
        chantime_ds=chantime.getDownSampled(1250,sdl.getActiveWorkspaceFile);
        channel=26;
%         SleepScoreMaster(chantime_ds.getFolder,...
%             'SWChannels',channel,'ThetaChannels',channel,...
%             'overwrite',false);        
        SleepScoreMaster(chantime_ds.getFolder,...
            'overwrite',false);
     
    end
    % OpenEphysRecordFactory.getOpenEphysRecord()
%     SleepScoreMaster('/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day04_NSD/merged_2019-Dec-27__04-49-48_20-03-08',...
%         'SWChannels',1,'ThetaChannels',1,...
%         'overwrite',false);
else
    for iday= [3]
        clearvars -except iday sdl folders funcs
        oerc=sdl.(funcs{iday});
        %% for spike detection save seperate shanks
        
        %% for oscillatory analyses select channels, downsample
        
        probe=oerc.getProbe;
        for ishank=1:4
            theshank=probe.getShank(ishank);
            chans=theshank.getActiveChannels;
            filename=oerc.mergeBlocksOfChannels(chans,...
                fullfile(folders{iday},sprintf('shank%d',ishank)));
        end
    end
end