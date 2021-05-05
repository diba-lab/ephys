classdef Preprocess
    %PREPROCESS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        OpenephysFiles
        Session
        ClusterParams
        LFPParams
        Bad
        Parameters
    end
    
    methods
        function obj = Preprocess(session)
            %PREPROCESS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Session = session;
            %% RawFiles
            sde=experiment.SDExperiment.instance.get;
            preprocessFile=fullfile(session.SessionInfo.baseFolder, sde.FileLocations.Preprocess.RawFiles);
            folder=fileparts(preprocessFile);
            if ~isfolder(folder), mkdir(folder);end
            try
                files=readstruct(preprocessFile);
            catch
                files.RawsFiles.RawFile(1)="[/folder/*.oebin | /folder/*.openephys]";
                files.RawsFiles.RawFile(2)="[/folder/*.oebin | /folder/*.openephys]";
                writestruct(files,preprocessFile);
                open preprocessFile
            end
            obj.OpenephysFiles=files.RawsFiles.RawFile';
            %% Set Sesion Info
            if isempty( session.SessionInfo.Date)
                sesInfo=session.SessionInfo;
                
                fInfo=dir(obj.OpenephysFiles(1));
                sesInfo.Date=datetime(fInfo.date,'InputFormat','dd-MMM-uuuu HH:mm:ss','Format','uuuu-MM-dd');
                session=session.setSessionInfo(sesInfo);
            end
            
            %% Read Params For Clustering
            paramsCluFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.ForClustering);
            try
                forClu=readstruct(paramsCluFile);
            catch
                forClu.Shanks.Shank=[1 2 3 4];
                animal=session.Animal.Code;
                date=session.SessionInfo.Date;
                if ~isdatetime(date)
                    error('Set Date of the session in SessionInfo File.')
                end
                cond=session.SessionInfo.Condition;
                output=sde.FileLocations.Preprocess.OutputFolderForClustering;
                forClu.OutputFolder=fullfile(output,strcat(animal,'_',datestr(date,29),'_',cond));
                writestruct(forClu,paramsCluFile);
            end
            obj.ClusterParams=forClu;
            %% Read Params For LFP
            paramsLFPFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.ForLFP);
            try
                forLFP=readstruct(paramsLFPFile);
            catch
                forLFP.Shanks.Shank=[1 2 3 4];
                forLFP.DownSampleRate=1250;
                
                writestruct(forLFP,paramsLFPFile);
            end
            obj.LFPParams=forLFP;
            %% Bad channel and time
            badFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Bad);
            try
                bad=readstruct(badFile);
            catch
                bad.BadChannels.Channel(1)=nan;
                bad.BadTimes.Time(1).Start=datetime('now','Format','HH:mm:ss.SSS');
                bad.BadTimes.Time(1).Stop=datetime('now','Format','HH:mm:ss.SSS')+seconds(5);
                bad.BadTimes.Time(1).Type='Type';
                writestruct(bad,badFile);
            end
            obj.Bad=bad;
            %% Params
            paramFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Parameters);
            try
                param=readstruct(paramFile);
            catch
                folder=fileparts(paramFile);
                param.cachefolder=fullfile(folder,'cache');
                param.Channels.Channel=1;
                param.ZScore.Threshold=[nan nan];
                param.ZScore.PlotYLims=[-3 3];
                param.ZScore.MinimumDurationInMs=500;
                param.ZScore.WindowsBeforeDetectionInMs=500;
                param.ZScore.WindowsAfterDetectionInMs=500;
                param.ZScore.MinimumInterArtifactDistanceInMs=500;
                param.ZScore.Downsample=250;
                freqbans=[1 4; 4 12];
                ZScoreThresholds=nan(size(freqbans));
                ZScorePlotYLims=[-.3 .5; -.5 1];
                param.Spectogram.FrequencyBands.start=freqbans(:,1);
                param.Spectogram.FrequencyBands.stop=freqbans(:,2);
                param.Spectogram.ZScore.Threshold.start=ZScoreThresholds(:,1);
                param.Spectogram.ZScore.Threshold.stop=ZScoreThresholds(:,2);
                param.Spectogram.ZScore.PlotYLims.start=ZScorePlotYLims(:,1);
                param.Spectogram.ZScore.PlotYLims.stop=ZScorePlotYLims(:,2);
                param.Spectogram.Method.chronux.WindowSize=2;
                param.Spectogram.Method.chronux.WindowStep=1;
                
                writestruct(param,paramFile);
            end
            obj.Parameters=param;
            
            %% Probe File
            probeRaw=fullfile(session.SessionInfo.baseFolder, sde.FileLocations.Session.Probe);
            probePrep=fullfile(session.SessionInfo.baseFolder, sde.FileLocations.Preprocess.Probe);
            copyfile(probeRaw,probePrep);
        end
        
        function dataForClustering = getDataForClustering(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            baseFolder=obj.Session.SessionInfo.baseFolder;
            
            outfol=obj.ClusterParams.OutputFolder;
            rawfiles=obj.OpenephysFiles;
            if ~isfolder(outfol), mkdir(outfol);end
            shanks=obj.ClusterParams.Shanks.Shank;
            
            cachestr=DataHash(strcat(convertStringsToChars(rawfiles')));
            oercCacheFile=fullfile(baseFolder,'cache',strcat(cachestr,'.mat'));
            if ~isfolder(fullfile(baseFolder,'cache')), mkdir(fullfile(baseFolder,'cache'));end
            try
                load(oercCacheFile,'oerc');
            catch
                for ifile=1:numel(rawfiles)
                    filename=fullfile(rawfiles{ifile});
                    oer =OpenEphysRecordFactory.getOpenEphysRecord(filename);
                    if ~exist('oerc','var')
                        oerc=OpenEphysRecordsCombined( oer);
                    else
                        oerc=oerc+oer;
                    end
                end
                save(oercCacheFile,'oerc')
            end
            
            sde=SDExperiment.instance.get;
            probeFile=fullfile(baseFolder,sde.FileLocations.Preprocess.Probe);
            probe=Probe(probeFile);
            if isempty(oerc.getProbe)
                oerc=oerc.setProbe(probe);
            end
            for ish=1:numel(shanks)
                aShank=shanks(ish);
                chans=probe.getShank(aShank).getActiveChannels;
                shankstr=strcat('shank',int2str(aShank) );
                outfolder=fullfile(outfol,shankstr);
                dataForClustering(ish)=oerc.mergeBlocksOfChannels(chans,outfolder);
            end
        end
        function dataForLFP = getDataForLFP(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            baseFolder=obj.Session.SessionInfo.baseFolder;
            session=obj.Session;
            
            toks=split(baseFolder,'/');
            name=toks{end};
            ext='.lfp';
            newFileName=fullfile(baseFolder,...
                sprintf('%s%s',name,ext));
            probe=session.Probe;
            shanks=obj.LFPParams.Shanks.Shank;
            newprobe=probe.getShank(shanks);
            if ~isfile(newFileName)
                rawfiles=obj.OpenephysFiles;
                cachestr=DataHash(strcat(convertStringsToChars(rawfiles')));
                oercCacheFile=fullfile(baseFolder,'cache',strcat(cachestr,'.mat'));
                if ~isfolder(fullfile(baseFolder,'cache')), mkdir(fullfile(baseFolder,'cache'));end
                try
                    load(oercCacheFile,'oerc');
                catch
                    for ifile=1:numel(rawfiles)
                        filename=fullfile(rawfiles{ifile});
                        oer =OpenEphysRecordFactory.getOpenEphysRecord(filename);
                        if ~exist('oerc','var')
                            oerc=OpenEphysRecordsCombined( oer);
                        else
                            oerc=oerc+oer;
                        end
                    end
                    save(oercCacheFile,'oerc');
                end
                if isempty(oerc.getProbe)
                    oerc=oerc.setProbe(probe);
                end
                channels=newprobe.getActiveChannels;
                mergedData=oerc.mergeBlocksOfChannels(channels,obj.ClusterParams.OutputFolder);
                
                chantime=ChannelTimeData(mergedData.DataFile);
                downsamplerate=obj.LFPParams.DownSampleRate;
                chantime_ds=chantime.getDownSampled(downsamplerate,newFileName);
%                 delete(mergedData.DataFile)
            end
            %             end
            dataForLFP=preprocessing.DataForLFP(newFileName);
            dataForLFP=dataForLFP.setProbe(newprobe);
            list=dir(fullfile(baseFolder,'*TimeIntervalCombined*'));
            ticd=neuro.time.TimeIntervalCombined(fullfile(baseFolder,list.name));
            dataForLFP=dataForLFP.setTimeIntervalCombined(ticd);
        end
        function arts=reCalculateArtifacts(obj)
            params=obj.getParameters;
            param_spec=params.Spectogram;
            params_chrx=param_spec.Method.chronux;
            freqs=[param_spec.FrequencyBands.start' param_spec.FrequencyBands.stop'];
            for ifreq=1:size(freqs,1)
                tfmethod=neuro.tf.TimeFrequencyChronuxMtspecgramc(...
                    freqs(ifreq,:),[params_chrx.WindowSize params_chrx.WindowStep]);
                if ~isfolder(params.cachefolder), mkdir(params.cachefolder);end
                cacheFile=fullfile(params.cachefolder, strcat(DataHash(tfmethod),'.mat'));
                if isfile(cacheFile)
                    load(cacheFile,'chPower');
                else
                    datalfp=obj.getDataForLFP;
                    ctd=datalfp.getChannelTimeData;
                    probe=ctd.getProbe;
                    chans=probe.getActiveChannels;
                    ch=ctd.getChannel(chans(params.Channels.Channel));
                    tfmap=ch.getTimeFrequencyMap(tfmethod);
                    powers=tfmap.matrix;
                    meanPower=mean(powers,2);
                    chPower=Channel(strcat('Power',sprintf(' %d-%d Hz',freqs(ifreq,:))),meanPower',tfmap.getTimeintervalCombined);
                    save(cacheFile,'chPower');
                end
                power{ifreq}=chPower;
                thld=[params.Spectogram.ZScore.Threshold.start' params.Spectogram.ZScore.Threshold.stop'];
                ylim=[params.Spectogram.ZScore.PlotYLims.start' params.Spectogram.ZScore.PlotYLims.stop'];
                if ~isnumeric(thld(ifreq,:))||sum(isnan(thld(ifreq,:)))
                    [artifacts_freq{ifreq}, zscoreThld]=obj.getArtifacts(chPower,[],ylim(ifreq,:));
                    params.Spectogram.ZScore.Threshold.start(ifreq)=zscoreThld(1);
                    params.Spectogram.ZScore.Threshold.stop(ifreq)=zscoreThld(2);
                    obj=obj.setParameters(params);

                else
                    [artifacts_freq{ifreq}]=obj.getArtifacts(...
                        chPower,thld(ifreq,:));
                end
            end
            if ~exist('ch','var')
                datalfp=obj.getDataForLFP;
                ctd=datalfp.getChannelTimeData;
                probe=ctd.getProbe;
                chans=probe.getActiveChannels;
                ch=ctd.getChannel(chans(params.Channels.Channel)); 
            end
            ch_ds=ch.getDownSampled(params.ZScore.Downsample);
            ch_ds=ch_ds.setChannelName('RawLFP');
            if ~isnumeric(params.ZScore.Threshold)
                [artifacts_rawLFP,zscoreThld]=obj.getArtifacts(ch_ds,[],params.ZScore.PlotYLims);
                params.ZScore.Threshold=zscoreThld;
                obj=obj.setParameters(params);
            else
                [artifacts_rawLFP]=obj.getArtifacts(ch_ds,params.ZScore.Threshold); 
            end
            bad=obj.getBad;
            combinedBad=artifacts_rawLFP;
            for ifreq=1:numel(artifacts_freq)
                combinedBad=combinedBad+artifacts_freq{ifreq};
            end
            bad.BadTimes.Time= table2struct( combinedBad.getTimeTable);
            obj=obj.setBad(bad);
            arts=preprocessing.Artifacts(obj,combinedBad,ch_ds,artifacts_freq,power);
        end

        
        function bad=getBad(obj)
            sde=experiment.SDExperiment.instance.get;
            badFile=fullfile(obj.Session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Bad);
            
            bad=readstruct(badFile);
        end
        function obj=setBad(obj,bad)
            sde=experiment.SDExperiment.instance.get;
            badFile=fullfile(obj.Session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Bad);
            writestruct(bad,badFile);
            obj.Bad=bad;
            
        end
        function param=getParameters(obj)
            sde=experiment.SDExperiment.instance.get;
            ParamFile=fullfile(obj.Session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Parameters);
            param=readstruct(ParamFile);
        end
        function obj=setParameters(obj,params)
            sde=experiment.SDExperiment.instance.get;
            paramFile=fullfile(obj.Session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Parameters);
            writestruct(params,paramFile);
            obj.Parameters=params;
        end
    end
    methods (Access=private)
        function  [timeWindows,zScoreThreshold]=getArtifacts(obj,channel,zScoreThreshold,ylim)
            params=obj.getParameters;
            zs=channel.getZScored;
            if isempty(zScoreThreshold) || sum(isnan(zScoreThreshold))
                % ask for the thresholds
                try close(1); catch, end; f=figure(1);f.Units='normalized';
                f.Position=[.5 .5 .5 .3 ];f.WindowStyle='docked';
                subplot(1, 5, 5);ax=gca;
                [N,edges]=histcounts(zs.getVoltageArray,'BinLimits',ylim,'Normalization','probability');
                edges(1)=[];
                centers=edges-(edges(2)-edges(1))/2;
                barh(ax,centers,N);
                ax.YLim=ylim;
                
                subplot(1, 5, 1:4);ax=gca;

                zs.plot;
                ax.YLim=ylim;

                ylabel(channel.getChannelName)
                res=ginput(1);
                ress(1)=res(2);
                yline(res(2));
                res=ginput(1);
                ress(2)=res(2);
                yline(res(2));
               
                close(1);
                zScoreThreshold(1)=min(ress);
                zScoreThreshold(2)=max(ress);
            end
            idx=zs<zScoreThreshold(1)|zs>zScoreThreshold(2);
            idx(1)=0;idx(end)=0;
            idx=[idx' 0];
            idx_edge=diff(idx);
            t(:,1)=find(idx_edge==1);
            t(:,2)=find(idx_edge==-1)+1;
            ticd=channel.getTimeIntervalCombined;
            addb=seconds(params.ZScore.WindowsBeforeDetectionInMs/1000);
            adda=seconds(params.ZScore.WindowsAfterDetectionInMs/1000);
            firstPass(:,1)=ticd.getRealTimeFor(t(:,1))-addb;
            firstPass(:,2)=ticd.getRealTimeFor(t(:,2))+adda;
            
            minInterArtifactDistInSec = params.ZScore.MinimumInterArtifactDistanceInMs/1000;
            finalTimeTable = [];
            countsecond=1;
            theArtifact = firstPass(1,:);
            for iart=2:size(firstPass,1)
                
                if seconds(firstPass(iart, 1) - theArtifact(2)) < minInterArtifactDistInSec
                    % Merging artifacts
                    [theArtifact(1),theArtifact(2)] = bounds([theArtifact(1) theArtifact(2) firstPass(iart,:)]);
                else
                    finalTimeTable(countsecond).Start= theArtifact(1);
                    finalTimeTable(countsecond).Stop= theArtifact(2);
                    finalTimeTable(countsecond).Type= strcat('ZScored_',channel.getChannelName);
                    countsecond=countsecond+1;
                    theArtifact = firstPass(iart,:);
                end
            end
            finalTimeTable= struct2table(finalTimeTable);
            timeWindows= neuro.basic.TimeWindows(finalTimeTable,ticd);
        end
    end
end

