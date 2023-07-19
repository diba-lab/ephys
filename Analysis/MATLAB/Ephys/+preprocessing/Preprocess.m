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
        Artifacts
    end
    
    methods
        function obj = Preprocess(session)
            %PREPROCESS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Session = session;
            %% RawFiles
            try
                sde=readstruct(fullfile(session.SessionInfo.baseFolder,'Parameters/Experiment.xml'));
            catch ME
                error(ME)
                sde=experiment.SDExperiment.instance.get;
            end
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
                forClu.Shanks.Shank=[nan nan];
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
                forLFP.Shanks.Shank=[nan nan];
                forLFP.Channels.Channel=[nan nan];
                forLFP.DownSampleRate=1250;
                
                writestruct(forLFP,paramsLFPFile);
            end
            obj.LFPParams=forLFP;
            %% Bad channel and time
            badFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Bad);
            try
                bad=readtable(badFile);
                bad.Start=seconds(bad.Start);
                bad.Stop=seconds(bad.Stop);
            catch
                bad=table([],[],'VariableNames',{'Start','Stop'});
                if ~isfolder(fileparts(badFile)), mkdir(fileparts(badFile));end
                writetable(bad,badFile);
                l=logging.Logger.getLogger;
                l.error('No bad file: %s',badFile);
            end
            obj.Bad=neuro.time.TimeWindowsDuration(bad);
            %% Params
            paramFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Parameters);
            cfg=[];
            try
                cfg=readstruct(paramFile);
            catch
                folder=fileparts(paramFile);
                cfg.cachefolder=fullfile(folder,'cache');
                cfg.channel=97:128;
                cfg.trialdef.triallength = 60;%seconds(hours(1));
                
                cfg.artfctdef.jump.channel      ='all';
                cfg.artfctdef.jump.interactive  = 'no';
                cfg.artfctdef.jump.artpadding  =.01;
                cfg.artfctdef.jump.interactive = 'yes';
                
                cfg.artfctdef.clip.channel      ='all';
                cfg.artfctdef.clip.timethreshold =.01;
                cfg.artfctdef.clip.amplthreshold ='1%';
                cfg.artfctdef.clip.pretim        =.02;
                cfg.artfctdef.clip.psttim        =.02;
                cfg.artfctdef.clip.interactive = 'yes';
                
                cfg.artfctdef.zvalue.channel      ='all';
                cfg.artfctdef.zvalue.cutoff     = 50;
                cfg.artfctdef.zvalue.artpadding = .01;
                cfg.artfctdef.zvalue.hilbert    ='yes';
                cfg.artfctdef.zvalue.bpfilter      = 'yes';
                cfg.artfctdef.zvalue.bpfreq        = [300 600];
                cfg.artfctdef.zvalue.interactive = 'yes';
                
                cfg.artfctdef.threshold.channel   = 'all';
                cfg.artfctdef.threshold.bpfilter  = 'no';
                cfg.artfctdef.threshold.bpfreq    = [0.3 80];
                cfg.artfctdef.threshold.bpfiltord = 4;
                cfg.artfctdef.threshold.range     = 1000;
                cfg.artfctdef.threshold.max       = 10000;
                
                writestruct(cfg,paramFile);
            end
            
            obj.Parameters=cfg;
            
            %% Probe File
            probeRaw=fullfile(session.SessionInfo.baseFolder, sde.FileLocations.Session.Probe);
            probePrep=fullfile(session.SessionInfo.baseFolder, sde.FileLocations.Preprocess.Probe);
            try
                copyfile(probeRaw,probePrep);
            catch
            end
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
                    oer =openEphys.OpenEphysRecordFactory.getOpenEphysRecord(filename);
                    if ~exist('oerc','var')
                        if isa(oer,'openEphys.OpenEphysRecord')
                            oerc=openEphys.OpenEphysRecordsCombined(oer);
                        elseif isa(oer,'openEphys.OpenEphysRecordsCombined')
                            oerc=oer;
                        end
                    else
                        oerc=oerc+oer;
                    end
                end
                save(oercCacheFile,'oerc')
            end
            readstr 
            sde=experiment.SDExperiment.instance.get;
            probeFile=fullfile(baseFolder,sde.FileLocations.Preprocess.Probe);
            probe=neuro.probe.Probe(probeFile);
            if isempty(oerc.getProbe)
                oerc=oerc.setProbe(probe);
            end
            evt=oerc.getEvents;
            for ish=1:numel(shanks)
                aShank=shanks(ish);
                chans=probe.getShank(aShank).getActiveChannels;
                shankstr=strcat('shank',int2str(aShank) );
                outfolder=fullfile(outfol,shankstr);
                l=logging.Logger.getLogger;
                try
                    evt.saveNeuroscopeEventFiles(outfolder,'On-Off');
                    l.fine('Event file saved.');
                catch
                    l.error('No event file saved.');
                end
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
            try
                chans=obj.LFPParams.Channels.Channel;
            catch
            end
            if exist('chans','var')
                if ~isstring(chans)
                    if ~sum(isnan(chans))
                        chans=chans'+1;
                    else
                        chans=[];
                    end
                else
                    chans=[];
                end
            else
                chans=[];
            end
            newprobe=probe.getShank(shanks);
            channels=newprobe.getActiveChannels;
            channels=[channels; chans];
            newprobe=probe.setActiveChannels(channels);
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
                        oer =openEphys.OpenEphysRecordFactory.getOpenEphysRecord(filename);
                        if ~exist('oerc','var')
                            oerc=openEphys.OpenEphysRecordsCombined( oer);
                        else
                            oerc=oerc+oer;
                        end
                    end
                    save(oercCacheFile,'oerc');
                end
                if isempty(oerc.getProbe)
                    oerc=oerc.setProbe(probe);
                end
                
                mergedData=oerc.mergeBlocksOfChannels(channels,obj.ClusterParams.OutputFolder);
                
                chantime=neuro.basic.ChannelTimeDataHard(mergedData.DataFile);
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
        function [obj]=reCalculateArtifacts(obj)
            cfg=obj.getParameters;
            ctdh=neuro.basic.ChannelTimeDataHard(obj.Session.SessionInfo.baseFolder);
            ctda=preprocessing.ChannelTimeDataArtifact(ctdh, cfg);
            ctda.saveArtifactsForNeuroscope
            obj.Artifacts=ctda.saveDeadFileForSpyKingCircus;
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
%         function [] = saveBadFile(obj)
%             bad=obj.getBad;
%             dataclu=obj.getDataForClustering;
%             ticd=dataclu.TimeIntervalCombined;
%             st=ticd.getSampleForClosest([obj.getBad.BadTimes.Time.Start])';
%             en1=ticd.getSampleForClosest([obj.getBad.BadTimes.Time.Stop])';
%             file1=round([st en1]/ticd.getSampleRate*1000);
%         end
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
            try
                idx=[0 idx'];
            catch
                idx=[0 idx]; 
            end
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

