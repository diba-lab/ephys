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
            sde=SDExperiment.instance.get;
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
            
            paramFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Parameters);
            try
                param=readstruct(paramFile);
            catch
                param.ZScore.Threshold=[-.5 1.5];
                param.ZScore.MinimumDurationInMs=0;
                param.ZScore.WindowsBeforeDetectionInMs=250;
                param.ZScore.WindowsAfterDetectionInMs=350;
                param.ZScore.MinimumInterArtifactDistanceInMs=500;
                param.ZScore.Downsample=250;
                
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
            %             if ~isfile(newFileName)
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
                probe=session.Probe;
                shanks=obj.LFPParams.Shanks.Shank;
                newprobe=probe.getShank(shanks);
                if isempty(oerc.getProbe)
                    oerc=oerc.setProbe(probe);
                end
                channels=newprobe.getActiveChannels;
                mergedData=oerc.mergeBlocksOfChannels(channels,obj.ClusterParams.OutputFolder);
                
                chantime=ChannelTimeData(mergedData.DataFile);
                downsamplerate=obj.LFPParams.DownSampleRate;
                chantime_ds=chantime.getDownSampled(downsamplerate,newFileName);
                delete(mergedData.DataFile)
            end
            %             end
            dataForLFP=DataForLFP(newFileName);
            dataForLFP=dataForLFP.setProbe(newprobe);
            list=dir(fullfile(baseFolder,'*TimeIntervalCombined*'));
            ticd=TimeIntervalCombined(fullfile(baseFolder,list.name));
            dataForLFP=dataForLFP.setTimeIntervalCombined(ticd);
        end
        function obj=reCalculateArtifacts(obj)
            params=obj.getParameters;
            thr=params.ZScore.Threshold;
            datalfp=obj.getDataForLFP;
            ctd=datalfp.getChannelTimeData;
            probe=ctd.getProbe;
            %             ctd1=ctd.saveKeepTimes(duration({'14:28:00','15:28:03';'17:30:00','17:30:03'}));
            %             ctd1=ctd.saveKeepTimes(duration({'13:50:00','14:45:00'}));
            chans=probe.getActiveChannels;
            ch=ctd.getChannel(chans(1));
            ch_ds=ch.getDownSampled(params.ZScore.Downsample);
            %             cfg = [];
            %             cfg.dataset     = 'Subject01.ds';
            %             data_meg        = ft_preprocessing(cfg);
            
            zs=ch_ds.getZScored;
            idx=zs<thr(1)|zs>thr(2);
            idx_edge=diff(idx);
            idx_edge=[0; idx_edge; 0];
            t(:,1)=find(idx_edge==1);
            t(:,2)=find(idx_edge==-1);
            ticd=ch_ds.getTimeIntervalCombined;
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
                    theArtifact = [theArtifact(1), firstPass(iart,2)];
                else
                    finalTimeTable(countsecond).Start= theArtifact(1);
                    finalTimeTable(countsecond).Stop= theArtifact(2);
                    finalTimeTable(countsecond).Type= 'ZScored';
                    countsecond=countsecond+1;
                    theArtifact = firstPass(iart,:);
                end
            end
            bad=obj.getBad;
            bad.BadTimes.Time=finalTimeTable;
            obj=obj.setBad(bad);
            
            try close(1); catch, end;figure(1);
            ch_plot=zs.getDownSampled(50);
            ch_plot.plot;ax=gca;hold on
            for iart=1:numel(finalTimeTable)
                art=finalTimeTable(iart);
                x=[art.Start art.Stop];
                y=[ax.YLim(2) ax.YLim(2)];
                p=area(x,y);
                p.BaseValue=ax.YLim(1);
                p.FaceAlpha=.5;
                p.FaceColor='r';
                p.EdgeColor='none';
            end
            yline(thr(1))
            yline(thr(2))
        end
        
        function bad=getBad(obj)
            sde=SDExperiment.instance.get;
            badFile=fullfile(obj.Session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Bad);
            
            bad=readstruct(badFile);
        end
        function obj=setBad(obj,bad)
            sde=SDExperiment.instance.get;
            badFile=fullfile(obj.Session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Bad);
            writestruct(bad,badFile);
            obj.Bad=bad;
            
        end
        function param=getParameters(obj)
            sde=SDExperiment.instance.get;
            ParamFile=fullfile(obj.Session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Parameters);
            param=readstruct(ParamFile);
        end
        function obj=setParameters(obj,params)
            sde=SDExperiment.instance.get;
            paramFile=fullfile(obj.Session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Parameters);
            writestruct(params,paramFile);
            obj.Parameters=params;
        end
    end
end

