classdef Preprocess
    %PREPROCESS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        OpenephysFiles
        Session
        ClusterParams
        LFPParams
        Bad
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
                bad.BadTimes.Time(1).start=datetime('now','Format','HH:mm:ss.SSS');
                bad.BadTimes.Time(1).stop=datetime('now','Format','HH:mm:ss.SSS')+seconds(5);
                bad.BadTimes.Time(2).start=datetime('now','Format','HH:mm:ss.SSS');
                bad.BadTimes.Time(2).stop=datetime('now','Format','HH:mm:ss.SSS')+seconds(5);
                writestruct(bad,badFile);
            end
            obj.Bad=bad;
            
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
            
            toks=tokenize(baseFolder,'/');
            name=toks{end};
            ext='.lfp';
            newFileName=fullfile(baseFolder,...
                sprintf('%s%s',name,ext));
            %             if ~isfile(newFileName)
            
            downsamplerate=obj.LFPParams.DownSampleRate;
            shanks=obj.LFPParams.Shanks.Shank;
            
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
            newprobe=probe.getShank(shanks);
            
            channels=newprobe.getActiveChannels;
            if ~isfile(newFileName)
                mergedData=oerc.mergeBlocksOfChannels(channels,obj.ClusterParams.OutputFolder);
                chantime=ChannelTimeData(mergedData.DataFile);
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
    end
end

