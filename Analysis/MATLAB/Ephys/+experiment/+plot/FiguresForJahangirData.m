classdef FiguresForJahangirData <Singleton
    %FIGURES Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Sessions
    end

    methods(Access=private)
        function obj = FiguresForJahangirData()
            % Initialise your custom properties.
            sf=experiment.SessionFactoryJ;
            obj.Sessions= sf.getSessions();
            sde=experiment.SDExperiment.instance.get;
            configureFileSWRRate=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','SWRRate.xml');
            try
                S=readstruct(configureFileSWRRate);
            catch
                S.Blocks.PRE=-3;
                S.Blocks.SD=5;
                S.Blocks.NSD=5;
                S.Blocks.TRACK=1;
                S.Blocks.RUN=1;
                S.Blocks.POST=3;
                S.Blocks.RS=3;
                S.Plot.SlidingWindowSizeInMinutes=30;
                S.Plot.SlidingWindowLapsInMinutes=30;
                writestruct(S,configureFileSWRRate)
            end
            structstruct(S);
            try
                pyenv("ExecutionMode","OutOfProcess");
            catch
            end

            configureFileFooof=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','Fooof.xml');
            try
                S=readstruct(configureFileFooof);
            catch
                S.Blocks.PRE=-3;
                S.Blocks.SD=5;
                S.Blocks.NSD=5;
                S.Blocks.TRACK=1;
                S.Blocks.RUN=1;
                S.Blocks.POST=3;
                S.Blocks.RS=3;
                S.Plot.SlidingWindowSizeInMinutes=30;
                S.Plot.SlidingWindowLapsInMinutes=30;
                writestruct(S,configureFileFooof)
            end
            structstruct(S);
        end
    end
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = experiment.plot.FiguresForJahangirData();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        function S=getParams(obj)
            sde=experiment.SDExperimentJ.instance.get;
            configureFileSWRRate=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','SWRRate.xml');
            S.SWRRate=readstruct(configureFileSWRRate);
            configureFileFooof=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','Fooof.xml');
            S.Fooof=readstruct(configureFileFooof);

        end
        function S=plotPowers(obj)
            ff=logistics.FigureFactory.instance;
            sde=experiment.SDExperiment.instance.get;
            T=readtable('SessionList.txt','Delimiter',',');
            conditions=unique(T.INJECTION);
            sess=obj.Sessions;
            cacheFile=fullfile(sde.FileLocations.General.PlotFolder,'CacheJA'...
                ,strcat('PlotFoof_Cond', DataHash(sess),'.mat'));
            clear Cond
            if ~isfile(cacheFile)

                for icond=1:numel(conditions)
                    idx=find(ismember(T.INJECTION,conditions{icond}));
                    for isession=1:numel(idx)
                        ses=sess(idx(isession));
                        file=ses.SessionInfo.baseFolder;
                        sdd=StateDetectionData(file);
                        blocks=ses.Blocks;
                        blocksStr=blocks.getBlockNames;
                        states={'A-WAKE','Q-WAKE','SWS','','REM',};
                        winDurations=[-3 1 5 3];
                        slidingWindowSize=minutes(30);
                        for iblock=1:numel(blocksStr)
                            block=blocksStr{iblock};
                            timeWindow=blocks.get(block);
                            winDuration=winDurations(iblock);
                            if winDuration>0
                                timeWindowadj=[timeWindow(1) timeWindow(1)+hours(winDuration)];
                                if timeWindowadj(2)>timeWindow(2)
                                    timeWindowadj(2)=timeWindow(2);
                                end
                            else
                                timeWindowadj=[timeWindow(2)+hours(winDuration) timeWindow(2)];
                                if timeWindowadj(1)<timeWindow(1)
                                    timeWindowadj(1)=timeWindow(1);
                                end
                            end
                            ss=sdd.getStateSeries;
                            ss_block=ss.getWindow(timeWindowadj);
                            edges=0:seconds(slidingWindowSize):seconds(hours(abs(winDuration)));
                            stateRatiosInTime=ss_block.getStateRatios(...
                                seconds(slidingWindowSize),[],edges);
                            subblocks=ss_block.getStartTime+seconds(edges);

                            thId=sdd.getThetaChannelID;
                            fname=strcat(sprintf('PlotFooof_%s_ses%d_ch%d_',conditions{icond},isession,thId));
                            fnamefull=strcat(fname,'.mat');
                            cacheCh=fullfile(sde.FileLocations.General.PlotFolder,'CacheJA'...
                                ,fnamefull);
                            try
                                load(cacheCh,'th')
                            catch
                                ctd=neuro.basic.ChannelTimeDataHard(file);
                                th=ctd.getChannel(thId);
                                save(cacheCh,'th');
                            end
                            try
                                allBlock=th.getTimeWindowForAbsoluteTime(timeWindowadj);
                            catch
                            end
                            fname=strcat(sprintf('PlotFooof_afoof_%s_ses%d_%d_',...
                                conditions{icond},isession, iblock), DataHash(timeWindowadj));
                            fnamefull=strcat(fname,'.mat');
                            cacheFilePower=fullfile(sde.FileLocations.General.PlotFolder,'CacheJA'...
                                ,fnamefull);
                            try
                                load(cacheFilePower,'fooof');
                            catch
                                try
                                    allBlock=th.getTimeWindowForAbsoluteTime(timeWindowadj);
                                    psd1=allBlock.getPSpectrumWelch;
                                    params=obj.getParams.Fooof;
                                    fooof=psd1.getFooof(params.Fooof,params.Fooof.f_range);
                                    fooof.plot;
                                    ff.save(fname)
                                    close(gcf);
                                    save(cacheFilePower,'fooof')
                                catch
                                    fooof=Fooof();
                                end
                            end
                            for istate=1:numel(stateRatiosInTime)
                                thestate=stateRatiosInTime(istate).state;
                                if sum(ismember([1 2 3 5],thestate))
                                    fname=strcat(sprintf('PlotFooof_afoof_%s_ses%d_%s_%s_',...
                                        conditions{icond},isession, block,states{thestate}),...
                                        DataHash(obj.getParams.Fooof), DataHash(timeWindowadj));
                                    fnamefull=strcat(fname,'.mat');
                                    cacheFilePower=fullfile(sde.FileLocations.General.PlotFolder,'CacheJA'...
                                        ,fnamefull);
                                    try
                                        load(cacheFilePower,'epiFooof')
                                    catch
                                        for isublock=1:(numel(subblocks)-1)
                                            try
                                                subblock=subblocks([isublock isublock+1]);
                                                subBlock=th.getTimeWindowForAbsoluteTime(subblock);
                                                ss_subBlock=ss_block.getWindow(subblock);
                                                stateEpisodes=ss_subBlock.getEpisodes;
                                                stateNames=ss_block.getStateNames;
                                                theStateName=stateNames{istate};
                                                theEpisode=stateEpisodes.(strcat(theStateName,'state'));
                                                ticdss=ss_subBlock.TimeIntervalCombined;
                                                theEpisodeAbs=ticdss.getRealTimeFor(theEpisode);
                                                episode=subBlock.getTimeWindow(theEpisodeAbs);
                                                ti=episode.getTimeInterval;
                                                dur=seconds(ti.getNumberOfPoints/ti.getSampleRate);
                                                %%
                                                params=obj.getParams.Fooof;
                                                if dur<minutes(params.Plot.MinDurationInSubBlockMinutes)
                                                    error('Short');
                                                end

                                                epiFooof(isublock)=episode.getPSpectrumWelch.getFooof(params.Fooof,params.Fooof.f_range);

                                                epiFooof(isublock).plot;
                                                ax=gca;
                                                ax.XLim=[1 100];
                                                ax.YLim=[1 6];
                                                ff.save(strcat(fname,num2str(isublock)));close;
                                            catch
                                                epiFooof(isublock)=Fooof();
                                            end
                                        end
                                        save(cacheFilePower,'epiFooof');
                                    end
                                    Cond(iblock).sratio(thestate,:,isession,icond)=stateRatiosInTime(thestate).Ratios;
                                    Cond(iblock).sCount(thestate,:,isession,icond)=stateRatiosInTime(thestate).N;
                                    Cond(iblock).edges(thestate,:,isession,icond)=stateRatiosInTime(thestate).edges;
                                    try
                                        Cond(iblock).fooof(thestate,:,isession,icond)=epiFooof;
                                    catch

                                    end
                                    clear epiFooof;
                                else
                                    Cond(iblock).fooof(4,:,isession,icond)=fooof;
                                end
                            end
                        end
                    end
                end
                folder=fileparts(cacheFile);
                if ~isfolder(folder), mkdir(folder);end
                save(cacheFile);
            else
                load(cacheFile,'Cond');
            end

            obj.plot_FooofInBlocks_CompareConditions(Cond)
        end
        function plotSWRRate(obj)
            sf=SessionFactory;
            s=obj.getParams;
            params=s.SWRRate;
            selected_ses=[1 2 3 4 5 6 7 8 9 10 14 15 16 17];
            tses=sf.getSessionsTable(selected_ses);
            sde=SDExperiment.instance.get;
            cacheFile=fullfile(sde.FileLocations.General.PlotFolder,'Cache'...
                ,strcat('PlotSWRRate_',DataHash(tses), DataHash(params),'.mat'));
            conditions=unique(tses.Condition);
            clear Cond
            if ~isfile(cacheFile)

                for icond=1:numel(conditions)
                    cond=conditions{icond};
                    filepath=tses.Filepath(  ismember(tses.Condition,cond));

                    tses_cond=sf.getSessions(filepath);

                    clear Ns ts Ns_adj;

                    for isession=1:numel(tses_cond)

                        if numel(tses_cond)>1
                            ses=tses_cond(isession);
                        else
                            ses=tses_cond;
                        end
                        file=ses.SessionInfo.baseFolder;
                        sdd=StateDetectionData(file);
                        blocks=ses.Blocks;
                        blocksStr=blocks.getBlockNames;
                        for iblock=1:numel(blocksStr)
                            block=blocksStr{iblock};
                            timeWindow=blocks.get(block);
                            winDuration=params.Blocks.(block);
                            if winDuration>0
                                timeWindowadj=[timeWindow(1) timeWindow(1)+hours(winDuration)];
                                if timeWindowadj(2)>timeWindow(2)
                                    timeWindowadj(2)=timeWindow(2);
                                end
                            else
                                timeWindowadj=[timeWindow(2)+hours(winDuration) timeWindow(2)];
                                if timeWindowadj(1)<timeWindow(1)
                                    timeWindowadj(1)=timeWindow(1);
                                end
                            end
                            ss=sdd.getStateSeries;
                            ss_block=ss.getWindow(timeWindowadj);
                            slidingWindowSize=minutes(params.Plot.SlidingWindowSizeInMinutes);
                            slidingWindowLaps=minutes(params.Plot.SlidingWindowLapsInMinutes);
                            edges=0:seconds(slidingWindowSize):seconds(hours(abs(winDuration)));
                            stateRatiosInTime=ss_block.getStateRatios(...
                                seconds(slidingWindowSize),[],edges);

                            bc=BuzcodeFactory.getBuzcode(file);
                            ripple=bc.calculateSWR;
                            ripple_block=ripple.getWindow(timeWindowadj);

                            stateEpisodes=ss_block.getEpisodes;
                            ripplePeaksInSeconds=ripple_block.getPeakTimes;
                            stateNames=ss_block.getStateNames;
                            clear rippleRates;
                            for istate=1:numel(stateRatiosInTime)

                                thestate=stateRatiosInTime(istate).state;
                                stateRatio=stateRatiosInTime(thestate);
                                try
                                    theStateName=stateNames{istate};
                                    theEpisode=stateEpisodes.(strcat(theStateName,'state'));
                                    idx_all=false(size(ripplePeaksInSeconds));
                                    for iepi=1:size(theEpisode,1)
                                        idx_epi=ripplePeaksInSeconds>theEpisode(iepi,1)...
                                            & ripplePeaksInSeconds<theEpisode(iepi,2);
                                        idx_all=idx_all|idx_epi;
                                    end
                                    stateRipplePeaksInSeconds=ripplePeaksInSeconds(idx_all);
                                    [rippleRates(thestate).N,rippleRates(thestate).edges] = histcounts( stateRipplePeaksInSeconds,stateRatio.edges);
                                    rippleRates(thestate).state=thestate;
                                catch
                                end
                            end
                            edges=stateRatiosInTime.edges;
                            for istate=1:numel(stateRatiosInTime)
                                thestate=stateRatiosInTime(istate).state;

                                if sum(ismember([1 2 3 5],thestate))
                                    Cond(iblock).sratio(thestate,:,isession,icond)=stateRatiosInTime(thestate).Ratios;
                                    Cond(iblock).sCount(thestate,:,isession,icond)=stateRatiosInTime(thestate).N;
                                    Cond(iblock).rCount(thestate,:,isession,icond)=rippleRates(thestate).N;
                                    Cond(iblock).edges(thestate,:,isession,icond)=rippleRates(thestate).edges;
                                end
                            end
                        end
                    end
                end
                folder=fileparts(cacheFile);
                if ~isfolder(folder), mkdir(folder);end
                save(cacheFile,'Cond');
            else
                load(cacheFile);
            end
            obj.plot_RippleRatesInBlocks_CompareConditions(Cond)
            obj.plot_RippleRatesInBlocks_CompareStates(Cond)

        end
        function plotFooof(obj,plotwh)
            if ~exist('plotwh','var')
                plotwh=1;
            end
            sf=experiment.SessionFactoryJ;
            selected_ses=[11:15];
%             selected_ses=[21 23];
            tses=sf.getSessionsTable(selected_ses);
            sde=experiment.SDExperimentJ.instance;
            sdeparams=sde.get;
            params=obj.getParams.Fooof;
            cacheFile=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache'...
                ,strcat('PlotFooof_',DataHash(tses), DataHash(params),'.mat'));
            if ~isfile(cacheFile)
                conditions=categorical(tses.INJECTION);
                conditionsCat=categories(conditions);
                clear Cond
                for icond=1:numel(conditionsCat)
                    cond=conditionsCat{icond};
                    filepath=tses.PATH(ismember(conditions,cond));
                    tses_cond=sf.getSessions(filepath);
                    
                    clear Ns ts Ns_adj;
                    sess=ordinal(1:numel(tses_cond));
                    for isession=1:numel(tses_cond)
                        theses=sess(isession);
                        if numel(tses_cond)>1
                            ses=tses_cond(isession);
                        else
                            ses=tses_cond;
                        end
                        file=ses.SessionInfo.baseFolder;
                        try
                            sdd=buzcode.sleepDetection.StateDetectionData(file);
                        catch
                        end
                        sdd.Info.SessionInfo=ses.SessionInfo;
                        EMG=sdd.getEMG;
                        ss=sdd.getStateSeries;
                        thId=sdd.getThetaChannelID;
                        try
                            ctd=neuro.basic.ChannelTimeDataHard(file);
                        catch
                        end        
                        th=ctd.getChannel(thId);
                        blocks=ses.Blocks;
                        blocksStr1=categorical([1 2 3 4],[1 2 3 4], ...
                            blocks.getBlockNames,'Ordinal',true);
                        blocksStr= blocksStr1([1 2 3 4]);
                        blocksStr= blocksStr1(3);
                        %                         blocksStr= blocksStr1;
                        for iblock=1:numel(blocksStr)
                            boc=neuro.basic.BlockOfChannels();
                            boc.Info.Condition=cond;
                            boc.Info.Session=theses;
                            boc.Info.SessionInfo=ses.SessionInfo;
                            boc.Info.Animal=ses.Animal;
                            boc.Info.Probe=ses.Probe;
                            block=blocksStr(iblock);
                            boc.Info.Block=block;
                            timeWindow=blocks.get(char(block));
                            winDuration=params.Blocks.(char(block));
                            if winDuration>0
                                timeWindowadj=[timeWindow(1) timeWindow(1)+hours(winDuration)];
                                if timeWindowadj(2)>timeWindow(2)
                                    timeWindowadj(2)=timeWindow(2);
                                end
                            else
                                timeWindowadj=[timeWindow(2)+hours(winDuration) timeWindow(2)];
                                if timeWindowadj(1)<timeWindow(1)
                                    timeWindowadj(1)=timeWindow(1);
                                end
                            end
                            allBlock=th.getTimeWindow(timeWindowadj);
                            boc=boc.addChannel(allBlock);
                            emg=EMG.getTimeWindow(timeWindowadj);
                            boc=boc.addChannel(emg);
                            ss_block=ss.getWindow(timeWindowadj);
                            boc=boc.addHypnogram(ss_block);
                            slidingWindowSize=minutes(params.Plot.SlidingWindowSizeInMinutes);
                            edges=0:seconds(slidingWindowSize):seconds(hours(abs(winDuration)));
                            stateRatiosInTime=boc.getStateRatios(...
                                seconds(slidingWindowSize),[],edges);
                            statelist=categorical(stateRatiosInTime.getStateList, ...
                                [1 2 3 5],{'AWAKE','QWAKE','SWS','REM'});
                            statelistnum=stateRatiosInTime.getStateList;
                            for istate=1:numel(statelist)
                                thestate=statelist(istate);
                                thestateNum=statelistnum(istate);
                                cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder, ...
                                    'Cache', DataHash(params)...
                                    ,strcat(sprintf('PlotFooof_afoof_%s_%s_%s_%s_', ...
                                    cond,ses.toString,block,thestate),'.mat'));
                                if isfile(cacheFilePower)
                                    load(cacheFilePower,'thpks','epiFooof')
                                else
                                    clear tfms thpks epiFooof
                                    subblocks=boc.getStartTime+seconds(edges);
                                    for isublock=1:(numel(subblocks)-1)
                                        subblock=subblocks([isublock isublock+1]);
                                        if subblock(1)< boc.getStartTime
                                            subblock(1)=boc.getStartTime;
                                        end
                                        if subblock(2)> boc.getEndTime
                                            subblock(2)=boc.getEndTime;
                                        end
                                        if subblock(2)>subblock(1)
                                            boc_sub=boc.getWindow(subblock);
                                            fooof=neuro.power.Fooof();
                                            thpk=experiment.plot.thetaPeak.ThetaPeak();
                                            if ~isempty(boc_sub)
                                                
                                                boc_sub.Info.SubBlock=categorical(isublock,1:(numel(subblocks)-1));
                                                [episode, theEpisodeAbs]=boc_sub.getState(thestateNum);
                                                if ~isempty(episode) && (episode{1}.getLength>minutes(params.Plot.MinDurationInSubBlockMinutes))
                                                    durations1=[0 cumsum(seconds(theEpisodeAbs(:,2)-theEpisodeAbs(:,1)))'];
                                                    thetaFreq=params.BandFrequencies.theta;
                                                    episode1=episode{1}.getDownSampled(50);
                                                    thpk=episode1.getFrequencyBandPeak(thetaFreq);
                                                    fooof=episode{1}.getPSpectrumWelch.getFooof(params.Fooof(2),params.Fooof(2).f_range);
                                                    fooof.Info=episode{1}.Info;
                                                    fooof.Info.episode =episode{1};
                                                    thpk=thpk.addFooof(fooof);
                                                    thpk.Bouts=durations1;
                                                    thpk.EMG=episode{2};
                                                end
                                            end
                                            epiFooof(isublock)=fooof; %#ok<AGROW>
                                            if exist('thpks','var')
                                                thpks=thpks.add(thpk,isublock);
                                            else
                                                thpks=thpk;
                                            end
%                                             if strcmpi( char(thestate),'AWAKE')
%                                                 try close(1); catch, end
%                                                 f=figure(1);
%                                                 f.Visible='on';
%                                                 f.Position=[1441,200,2800,1100];
%                                                 
%                                                 obj.plotEpisode(boc_sub,params,thestate);%awake
%                                                 
%                                                 fname=strcat(sprintf(
% '/home/ukaya/Desktop/theta-cf/%s/%s/%s/PlotFooof_afoof_ses%d_sub%d_%s',block,
% thestate,cond,isession,isublock),DataHash(params));
%                                                 ff=logistics.FigureFactory.instance;
%                                                 ff.save(fname);
%                                                 %Plot end
%                                             end
                                        end
                                        
                                    end
                                    folder=fileparts(cacheFilePower);
                                    if ~isfolder(folder), mkdir(folder); end
                                    save(cacheFilePower,'thpks','epiFooof');
                                end
                                %                                     thpks.plotCF
                                %                                     thpks.plotPW
                                stt=stateRatiosInTime.State(istate).state;
                                try
                                    Cond(iblock).sratio(stt,:,isession,icond)=stateRatiosInTime.State(istate).Ratios; %#ok<AGROW>
                                    Cond(iblock).sCount(stt,:,isession,icond)=stateRatiosInTime.State(istate).N; %#ok<AGROW>
                                    Cond(iblock).edges(stt,:,isession,icond)=stateRatiosInTime.State(istate).edges; %#ok<AGROW>
                                catch
                                    Cond(iblock).sratio(stt,:,isession,icond)=nan; %#ok<AGROW>
                                    Cond(iblock).sCount(stt,:,isession,icond)=nan; %#ok<AGROW>
                                    Cond(iblock).edges(stt,:,isession,icond)=nan; %#ok<AGROW>
                                end
                                try
                                    Cond(iblock).fooof(stt,:,isession,icond)=epiFooof; %#ok<AGROW>
                                catch
                                    Cond(iblock).fooof(stt,:,isession,icond)=neuro.power.Fooof(); %#ok<AGROW>
                                end
                                clear epiFooof;
                            end
                        end
                    end
                end
                folder=fileparts(cacheFile);
                if ~isfolder(folder), mkdir(folder);end
                save(cacheFile,'Cond');
            else
                load(cacheFile,'Cond');
            end
            obj.plot_FooofInBlocks_CompareConditions(Cond,plotwh)
        end
        function thpkc=getThetaPeaks(obj)
            sde=experiment.SDExperimentJ.instance;
            sdeparams=sde.get;
            params=obj.getParams.Fooof;
            sf=experiment.SessionFactoryJ;
            selected_ses=[1:15];
            %             selected_ses=[21 23];
            tses=sf.getSessionsTable(selected_ses);

            statelist=categorical({'AWAKE','QWAKE','SWS','REM'});
            condlist=categorical(unique(tses.INJECTION));
            blocklist=categorical({'PRE','NSD','SD','RUN','RS'});
            
            conds=condlist;
            blocks=blocklist(1:5);
            states=statelist(:);
            for icond=1:numel(conds)
                cond=conds(icond);
                sesc=tses(ismember(tses.INJECTION,cond),:);
                for isession=1:height(sesc)
                    sesfilepath=sesc(isession,"PATH").PATH;sesfilepath=sesfilepath{:};
                    ses=sf.getSessions(sesfilepath);
                    for iblock=1:numel(blocks)
                        block=blocks(iblock);
                        for istate=1:numel(states)
                            state=states(istate);
                            cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache',['' DataHash(params)]...
                                ,strcat(sprintf('PlotFooof_afoof_%s_%s_%s_%s_',cond,ses.toString,block,state),'.mat'));
                            if isfile(cacheFilePower)
                                S=load(cacheFilePower,'thpks','epiFooof');
                                try
                                    S.thpks.Info.Session=ses;
                                    thpks.(char(cond)).(char(block)).(char(state)).(['ses' num2str(isession)])=S.thpks;
                                    fooof.(char(cond)).(char(block)).(char(state)).(['ses' num2str(isession)])=S.epiFooof;
                                catch
                                end
                            end
                        end
                    end
                end
            end
            thpkc=experiment.plot.thetaPeak.ThetaPeaksContainer3(thpks,fooof,params);
        end

    end
    methods (Access=private)
        function plot_RippleRatesInBlocks_CompareStates(obj,Conds)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            s=obj.getParams;
            params=s.SWRRate;
            colorsall=linspecer(10,'sequential');
            colors=colorsall([10 8 1 5 3],:);
            conditions={'NSD','SD'};
            blockstr={'PRE','SD/NSD','TRACK','POST'};
            states=[1 2 3 5];

            for icond=1:numel(conditions)

                try close(icond);catch;end; f=figure(icond);f.Units='normalized';f.Position=[1.0000    0.4391    1.4    0.2];
                lastedge=0;
                centers_all=[];
                edges_all=[];
                centers_num=[];
                for iblock=1:size(Conds,2)
                    rcount=Conds(iblock).rCount(:,:,:,icond);
                    scount=Conds(iblock).sCount(:,:,:,icond);
                    scount(scount<seconds(minutes(1)))=nan;
                    rrate=rcount./scount;
                    numses=size(rcount,3);




                    edges=hours(seconds(Conds(iblock).edges(1,:,1,icond)))+lastedge;
                    lastedge=edges(end);
                    centers=edges(2:end)-(edges(2)-edges(1))/2;
                    centers_all=[centers_all centers] ;
                    edges_all=[edges_all edges] ;
                    centers_num=[centers_num numel(centers)];
                    subplot(10,1,1:9);
                    scountSum= minutes(seconds(sum(scount,3,'omitnan')));
                    scountmean=scountSum./sum(scountSum,1,'omitnan')*params.Plot.SlidingWindowSizeInMinutes;
                    yyaxis left
                    b=bar(centers, scountmean','stacked','BarWidth',1,'FaceAlpha',.3);
                    ax=gca;
                    %                     ax.XTick=edges;
                    ax.YLim=[0 params.Plot.SlidingWindowSizeInMinutes];
                    ylabel('State Duration (min)');
                    xlabel('Time (h)');
                    hold on
                    yyaxis right
                    rratemean=nanmean(rrate,3);
                    rcountmean=nanmean(rcount,3);
                    rrateErr=nanstd(rrate,[],3)/sqrt(size(rrate,3));
                    centersall=repmat(centers,size(rratemean,1),1);
                    p=errorbar(centersall', rratemean',rrateErr','-','Marker','.','MarkerSize',20);

                    centershift=([1 2 3 3 4]-2.5)*.05;
                    for iplot=1:numel(p)
                        rrateSes=squeeze(rrate(iplot,:,:));
                        thecolor=colors(iplot,:);
                        plot(centers+centershift(iplot),rrateSes,'Color',thecolor, ...
                            'LineWidth',.2,'Marker','.','MarkerSize',10,'LineStyle','none')
                        b(iplot).FaceColor=thecolor;
                        b(iplot).LineWidth=.2;
                        p(iplot).Color=thecolor;
                        p(iplot).LineWidth=2;
                    end
                end
                legend([b(1) b(2) b(3) b(5)],{'A-WAKE','Q-WAKE','SWS','REM'},'Location','best')
                title(conditions{icond});
                ax=gca;
                ax.YColor='k';
                ax.YLim=[0 1.6];
                ax.XLim=[0 edges(end)];
                ax.XTick=unique(edges_all);
                it=1;
                for iblock=1:numel(centers_num)
                    for i=1:centers_num(iblock)
                        str=blockstr{iblock};
                        if strcmp(str,'SD/NSD'), str=conditions{icond};end
                        text(centers_all(it),-diff(ax.YLim)*.05,strcat(str), ...
                            'HorizontalAlignment','center');
                        it=it+1;
                    end
                end
                ylabel('SWR rate (#/s)');
                ff=FigureFactory.instance;
                ff.save(strcat('RipleRate_',conditions{icond}));
            end
        end
        function plot_RippleRatesInBlocks_CompareConditions(obj,Conds)
            s=obj.getParams;
            params=s.SWRRate;
            colorsall=linspecer(10,'sequential');
            colors=colorsall([1 10 1 5 3],:);
            conditions={'NSD','SD'};
            blockstr={'PRE','SD/NSD','TRACK','POST'};
            states=[1 2 3 5];
            statestr={'A-WAKE','Q-WAKE','SWS','SWS','REM'};
            for thestate=states
                try close(thestate);catch;end; f=figure(thestate);
                f.Units='normalized';f.Position=[1 .4391 .2 .2];
                lastedge=0;
                centers_all=[];
                edges_all=[];
                centers_num=[];
                for iblock=1:size(Conds,2)
                    rcount=squeeze(Conds(iblock).rCount(thestate,:,:,:));
                    scount=squeeze(Conds(iblock).sCount(thestate,:,:,:));
                    scount(scount<seconds(minutes(1)))=nan;
                    rrate=rcount./scount;
                    numses=size(rcount,2);
                    edgesall=hours(seconds(Conds(iblock).edges(:,:,:,:)));
                    edgesf=0;
                    for istate=1:size(edgesall,1)
                        for ises=1:size(edgesall,3)
                            for icond=1:size(edgesall,4)
                                edges1=edgesall(istate,:,ises,icond);
                                if numel(unique(edges1))>numel(edgesf)
                                    edgesf=edges1;
                                end
                            end
                        end
                    end
                    edges=edgesf+lastedge;
                    lastedge=edges(end);
                    centers=edges(2:end)-(edges(2)-edges(1))/2;
                    centers_all=[centers_all centers] ;
                    edges_all=[edges_all edges] ;
                    centers_num=[centers_num numel(centers)];
                    subplot(10,1,1:9);
                    scountmean= squeeze(minutes(seconds(nanmean(scount,2))));
                    yyaxis left
                    b=bar(centers, scountmean','stacked','BarWidth',1,'FaceAlpha',.3);
                    ax=gca;
                    %                     ax.XTick=edges;
                    %                     ax.YLim=[0 obj.Params.Plot.SlidingWindowSizeInMinutes];
                    ylabel('State Duration (min)');
                    xlabel('Time (h)');
                    hold on
                    yyaxis right
                    rratemean=squeeze(nanmean(rrate,2));
                    rcountmean=squeeze(nanmean(rcount,2));
                    rrateErr=squeeze(nanstd(rrate,[],2))/sqrt(size(rrate,2));
                    centersall=repmat(centers,size(rratemean,2),1)';
                    p=errorbar(centersall, rratemean,rrateErr,'-','Marker','.','MarkerSize',20);

                    centershift=([0 1]-.5)*.05;
                    for iplot=1:numel(p)
                        rrateSes=squeeze(rrate(:,:,iplot));
                        thecolor=colors(iplot,:);
                        plot(centers+centershift(iplot),rrateSes,'Color', ...
                            thecolor,'LineWidth',.2,'Marker','.','MarkerSize',10,'LineStyle','none')
                        b(iplot).FaceColor=thecolor;
                        b(iplot).LineWidth=.2;
                        p(iplot).Color=thecolor;
                        p(iplot).LineWidth=1.5;
                    end
                end
                legend([b(1) b(2)],conditions,'Location','best')
                title(statestr{thestate});
                ax=gca;
                ax.YColor='k';
                ax.YLim=[0 1.6];
                ax.XLim=[0 edges(end)];
                ax.XTick=unique(edges_all);
                it=1;
                for iblock=1:numel(centers_num)
                    for i=1:centers_num(iblock)
                        str=blockstr{iblock};
                        text(centers_all(it),-diff(ax.YLim)*.05,strcat(str), ...
                            'HorizontalAlignment','center');
                        it=it+1;
                    end
                end
                ylabel('SWR rate (#/s)');
                ff=FigureFactory.instance;
                ff.save(strcat('RipleRate_',statestr{thestate}));
            end
        end
        function plot_FooofInBlocks_CompareConditions(obj,Conds,param)
            s=obj.getParams;
            peaksCF=[5 9];
            colors1=linspecer(3,'qualitative');
            colors={colors1(1,:);colors1(2,:);colors1(3,:)};
            conditions={'CTRL','OCT','ROL'};
            blockstr={'PRE','TRACK','SD','POST'};
            states=[1 2 3 5];
            statestr={'A-WAKE','Q-WAKE','SWS','all','REM'};
            ff=logistics.FigureFactory.instance;
            for thestate=states
                try close(thestate);catch;end; f=figure(thestate);f.Units='normalized';
                f.Position=[1.0000    0.4391    .2    0.2];
                lastedge=0;
                centers_all=[];
                edges_all=[];
                centers_num=[];
                for iblock=1:size(Conds,2)
                    scount=squeeze(Conds(iblock).sCount(thestate,:,:,:));
                    scount(scount<seconds(minutes(1)))=nan;
                    edgesall=squeeze(hours(seconds(Conds(iblock).edges(:,:,:,:))));
                    edgesf=0;
                    for istate=1:size(edgesall,1)
                        for ises=1:size(edgesall,3)
                            for icond=1:size(edgesall,4)
                                edges1=edgesall(istate,:,ises,icond);
                                if numel(unique(edges1))>numel(edgesf)
                                    edgesf=edges1;
                                end
                            end
                        end
                    end
                    edges=edgesf+lastedge;
                    lastedge=edges(end);
                    centers=edges(2:end)-(edges(2)-edges(1))/2;
                    centers_all=[centers_all centers] ;
                    edges_all=[edges_all edges] ;
                    centers_num=[centers_num numel(centers)];
                    scountmean= squeeze(minutes(seconds(nanmean(scount,2))));
                    yyaxis left
                    b=bar(centers, scountmean','stacked','BarWidth',1,'FaceAlpha',.3);
                    ax=gca;
                    %                     ax.XTick=edges;
                    %                     ax.YLim=[0 obj.Params.Plot.SlidingWindowSizeInMinutes];
                    ylabel('State Duration (min)');
                    xlabel('Time (h)');
                    hold on
                    yyaxis right
                    fooofs=squeeze(Conds(iblock).fooof(thestate,:,:,:));
                    clear sub_ses_cond
                    for isub=1:size(fooofs,1)
                        for ises=1:size(fooofs,2)
                            for icond=1:size(fooofs,3)
                                fooof=fooofs(isub,ises,icond);
                                %                                 try
                                %                                     fooof.plot
                                %                                     ax=gca;
                                %                                     ax.YLim=[2.5 6.5];
                                %                                     ff.save(sprintf('%s_%s_sub%d_ses%d_%s',statestr{thestate},...
                                %                                         blockstr{iblock},isub,ises,conditions{icond}));
                                %                                 catch
                                %                                 end
                                %                                 close
                                try
                                    sub_ses_cond.thetaPeak.cf(isub,ises,icond)=fooof.getPeak(peaksCF).cf;
                                catch
                                    sub_ses_cond.thetaPeak.cf(isub,ises,icond)=nan;
                                end
                                try
                                    sub_ses_cond.thetaPeak.power(isub,ises,icond)=fooof.getPeak(peaksCF).power;
                                catch
                                    sub_ses_cond.thetaPeak.power(isub,ises,icond)=nan;
                                end
                                try
                                    sub_ses_cond.thetaPeak.bw(isub,ises,icond)=fooof.getPeak(peaksCF).bw;
                                catch
                                    sub_ses_cond.thetaPeak.bw(isub,ises,icond)=nan;
                                end
                                try
                                    sub_ses_cond.aperiodic.offset(isub,ises,icond)=fooof.fooof_results.aperiodic_params(1);
                                catch
                                    sub_ses_cond.aperiodic.offset(isub,ises,icond)=nan;
                                end
                                try
                                    sub_ses_cond.aperiodic.f(isub,ises,icond)=fooof.fooof_results.aperiodic_params(end);
                                catch
                                    sub_ses_cond.aperiodic.f(isub,ises,icond)=nan;
                                end

                            end
                        end
                    end
                    %                     var=sub_ses_cond.thetaPeak.cf;
                    var=sub_ses_cond.thetaPeak.power;
                    %                     var=sub_ses_cond.aperiodic.f;
                    %                     var=sub_ses_cond.aperiodic.offset;
                    meanval=squeeze(nanmean(var,2));
                    errval=squeeze(nanstd(var,[],2))/sqrt(size(var,2));
                    centers2=repmat(centers,size(meanval,2),1)';
                    perrbar=errorbar(centers2, meanval,errval,'-','Marker','.','MarkerSize',20);
                    clear meanval errval
                    centershift=([0 1 2 3]-1.5)*.1;
                    for iplot=1:numel(perrbar)
                        varSes=squeeze(var(:,:,iplot));
                        thecolor=colors{iplot};
                        plot(centers+centershift(iplot),varSes,'Color',thecolor, ...
                            'LineWidth',.2,'Marker','.','MarkerSize',10,'LineStyle','none')
                        clear varSes
                        b(iplot).FaceColor=thecolor;
                        b(iplot).LineWidth=.2;
                        perrbar(iplot).Color=thecolor;
                        perrbar(iplot).LineWidth=2;
                    end
                end
                legend([b(1) b(2) b(3)],conditions,'Location','best')
                title(statestr{thestate});
                ax=gca;
                ax.YColor='k';
                %                 ax.YLim=peaksCF;%CF
                ax.YLim=[.1 1.4];%power
                %                 ax.YLim=[.1 1.4];%power
                %                 ax.YLim=[1 2.5];%slope
                %                 ax.YLim=[4.5 7.5];%offset
                ax.XLim=[0 edges(end)];
                ax.XTick=unique(edges_all);
                it=1;
                for iblock=1:numel(centers_num)
                    for i=1:centers_num(iblock)
                        str=blockstr{iblock};
                        text(centers_all(it),ax.YLim(1)-diff(ax.YLim)*.05,strcat(str), ...
                            'HorizontalAlignment','center');
                        it=it+1;
                    end
                end
                %                 ylabel('Center Frequency (Hz)');
                ylabel('Relative Power');
                %                 ylabel('F');
                %                 ylabel('Offset');
                ff=FigureFactory.instance;
                %                 ff.save(strcat('Center Frequency_',statestr{thestate}));
                ff.save(strcat('Power_',statestr{thestate}));
                %                 ff.save(strcat('f_',statestr{thestate}));
                %                 ff.save(strcat('Offset_',statestr{thestate}));
            end
        end
    end

end
