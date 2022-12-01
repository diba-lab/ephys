 classdef SDFigures2 <Singleton
    %FIGURES Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Sessions
    end

    methods(Access=private)
        function obj = SDFigures2()
            % Initialise your custom properties.
            sf=experiment.SessionFactory;
            obj.Sessions= sf.getSessions();
            sde=experiment.SDExperiment.instance.get;
            configureFileSWRRate=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','SWRRate.xml');
            try
                S=readstruct(configureFileSWRRate);
            catch
                S.Blocks.PRE=-3;
                S.Blocks.SD=5;
                S.Blocks.TRACK=1;
                S.Blocks.POST=3;
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
                S.Blocks.TRACK=1;
                S.Blocks.POST=3;
                S.Plot.SlidingWindowSizeInMinutes=30;
                S.Plot.SlidingWindowLapsInMinutes=30;
                writestruct(S,configureFileFooof)
            end
            structstruct(S);
        end
    end
    methods (Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = experiment.plot.SDFigures2();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        function S=getParams(~)
            sde=experiment.SDExperiment.instance.get;
            configureFileSWRRate=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','SWRRate.xml');
            S.SWRRate=readstruct(configureFileSWRRate);
            configureFileFooof=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','Fooof.xml');
            S.Fooof=readstruct(configureFileFooof);

        end
        function [swrt, trexp ]=getSWRRates(obj)

            sf=experiment.SessionFactory;
            s=obj.getParams;
            params=s.SWRRate;
            selected_ses=1:23;selected_ses([3 13 16 17])=[];
%             selected_ses=1:2;
            tses=sf.getSessionsTable(selected_ses);
%             SWRarr=neuro.ripple.RippleAbs.empty(height(tses),0);
            %%
            cachefile='plotSWRCache';
            if isfile(cachefile)
                load(cachefile);
            else
                for isession=1:height(tses)
                    sesr=tses(isession,:);
                    ses=sf.getSessions(sesr.Filepath);
                    sesss(isession)=ses;
                    file=ses.SessionInfo.baseFolder;
                    bc=buzcode.BuzcodeFactory.getBuzcode(file);
                    ripple=bc.calculateSWR;
                    condsarr{isession}=sesr.Condition{1};
                    try
                    SWRarr(isession)=ripple;
                    catch
                    end
                    %%
                    sdd=buzcode.sleepDetection.StateDetectionData(file);
                    blocks=ses.Blocks;
                    blocksStr=blocks.getBlockNames;
                    blocksStrc=categorical(blocks.getBlockNames);
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
                        edges=0:seconds(slidingWindowSize):seconds(hours(abs(winDuration)));
                        stateRatiosInTime1=ss_block.getStateRatios(...
                            seconds(slidingWindowSize),[],edges);
                        stateRatiosInTime=stateRatiosInTime1.State;
                        ripple_block=ripple.getWindow(timeWindowadj);
                        stateEpisodes=ss_block.getEpisodes;
                        ripplePeaksInSeconds=ripple_block.getPeakTimes;
                        stateNames=ss_block.getStateNames;
                        stateNamesc=categorical(ss_block.getStateNames);
                        clear rippleRates;
                        for istate=1:numel(stateRatiosInTime)
                            thestate=stateRatiosInTime(istate).state;
                            stateRatio=stateRatiosInTime(istate);
                            %%
                            theStateName=stateNames{thestate};
                            theEpisode=stateEpisodes.(strcat(theStateName,'state'));
                            idx_all=false(size(ripplePeaksInSeconds));
                            for iepi=1:size(theEpisode,1)
                                idx_epi=ripplePeaksInSeconds>theEpisode(iepi,1)...
                                    & ripplePeaksInSeconds<theEpisode(iepi,2);
                                idx_all=idx_all|idx_epi;
                            end
                            stateRipplePeaksInSeconds=ripplePeaksInSeconds(idx_all);
                            [rippleRates(istate).RippleCount,rippleRates(istate).Edges] = ...
                                histcounts( stateRipplePeaksInSeconds,stateRatio.edges); %#ok<AGROW>
                            rippleRates(istate).RippleCount=rippleRates(istate).RippleCount';
                            rippleRates(istate).State=stateNamesc(thestate); %#ok<AGROW>
                        end
                        trip=struct2table(rippleRates,AsArray=1);
                        trat=struct2table(stateRatiosInTime,AsArray=1);
                        t1=trip(:,{'State','Edges','RippleCount'});
                        t2=trat(:,{'Ratios','N'});
                        t2.Properties.VariableNames={'StateRatio','StateCountsSeconds'};
                        trblock=[t1 t2];
                        trblock.Block=repmat(blocksStrc(iblock),height(trblock),1);
                        trblock.SessionNo=repmat(sesr.SessionNo,height(trblock),1);
                        try
                            trses=[trses;trblock];
                        catch
                            trses=trblock;
                        end
                        clear trblock
                    end
                    try
                        trexp=[trexp;trses];
                    catch
                        trexp=trses;
                    end
                    clear trses
                end
                save(cachefile,'SWRarr',"trexp");
            end
            swrt=table(categorical(condsarr'),SWRarr',sesss','VariableNames',{'Condition','SWR','Sessions'});

        end
        function plotFooof(obj,plotwh)
            if ~exist('plotwh','var')
                plotwh=1;
            end
            sf=experiment.SessionFactory;
            selected_ses=[1:12 14:15 18:23 ];
%             selected_ses=[1 2 11 12 21 22 ];
            tses=sf.getSessionsTable(selected_ses);
            sde=experiment.SDExperiment.instance;
            sdeparams=sde.get;
            params=obj.getParams.Fooof;
            cacheFile=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache'...
                ,strcat('PlotFooof_',DataHash(tses), DataHash(params),'.mat'));
            if ~isfile(cacheFile)
                conditions=categorical(tses.Condition);
                conditionsCat=categories(conditions);
                clear Cond
                for icond=1:numel(conditionsCat)
                    cond=conditionsCat{icond};
                    filepath=tses.Filepath(  ismember(conditions,cond));
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
                            SPD=ses.getPosition.getSpeed;
                        catch
                        end
                        sdd=buzcode.sleepDetection.StateDetectionData(file);
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
                        blocksStr1=categorical([1 2 3 4],[1 2 3 4],blocks.getBlockNames,'Ordinal',true);
                        blocksStr= blocksStr1([1 2 3 4]);
                        blocksStr= blocksStr1([2]);
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
                            try
                                spd=SPD.getTimeWindow(timeWindowadj);
                                boc=boc.addChannel(spd);
                            catch
                            end
                            ss_block=ss.getWindow(timeWindowadj);
                            boc=boc.addHypnogram(ss_block);
                            slidingWindowSize=minutes(params.Plot.SlidingWindowSizeInMinutes);
                            edges=0:seconds(slidingWindowSize):seconds(hours(abs(winDuration)));
                            stateRatiosInTime=boc.getStateRatios(...
                                seconds(slidingWindowSize),[],edges);
                            statelist=categorical(stateRatiosInTime.getStateList,[1 2 3 5],{'AWAKE','QWAKE','SWS','REM'});
                            statelistnum=stateRatiosInTime.getStateList;
                            for istate=1:numel(statelist)
                                thestate=statelist(istate);
                                thestateNum=statelistnum(istate);
                                cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache', DataHash(params)...
                                    ,strcat(sprintf('PlotFooof_afoof_%s_%s_%s_%s_',cond,ses.toString,block,thestate),'.mat'));
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
                                                    try
                                                        thpk.Speed=episode{3};
                                                    catch
                                                    end
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
                                            %                                                 fname=strcat(sprintf('/home/ukaya/Desktop/theta-cf/%s/%s/%s/PlotFooof_afoof_ses%d_sub%d_%s',block,thestate,cond,isession,isublock),DataHash(params));
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
            sde=experiment.SDExperiment.instance;
            sdeparams=sde.get;
            params=obj.getParams.Fooof;
            sf=experiment.SessionFactory;
            selected_ses=[1:2 4:12 14:17 20:23];
%             selected_ses=[1 2 11 12 21 22 ];
            tses=sf.getSessionsTable(selected_ses);

            statelist=categorical({'AWAKE','QWAKE','SWS','REM'});
            condlist=categorical({'NSD','SD'});
            blocklist=categorical({'PRE','NSD','SD','TRACK','POST'});

            conds=condlist(1:2);
            blocks=blocklist(1:5);
            states=statelist(:);
            for icond=1:numel(conds)
                cond=conds(icond);
                sesc=tses(ismember(tses.Condition,cond),:);
                for isession=1:height(sesc)
                    sesfilepath=sesc(isession,"Filepath").Filepath;sesfilepath=sesfilepath{:};
                    sesno=sesc(isession,"SessionNo").SessionNo;
                    ses=sf.getSessions(sesfilepath);
                    for iblock=1:numel(blocks)
                        block=blocks(iblock);
                        for istate=1:numel(states)
                            state=states(istate);
                            cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache',['' DataHash(params)]...
                                ,strcat(sprintf('PlotFooof_afoof_%s_%s_%s_%s_',cond,ses.toString,block,state),'.mat'));
                            cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache',['dd0ec70abdf774dc65dbfe6051420a73']...
                                ,strcat(sprintf('PlotFooof_afoof_%s_%s_%s_%s_%s_',cond,ses.Animal.Code,ses.SessionInfo.Date,block,state),'.mat'));
                            if isfile(cacheFilePower)
                                S=load(cacheFilePower,'thpks','epiFooof');
                                try
                                    S.thpks.Info.Session=ses;
                                    thpks.(char(cond)).(char(block)).(char(state)).(['ses' num2str(sesno)])=S.thpks;
                                    fooof.(char(cond)).(char(block)).(char(state)).(['ses' num2str(sesno)])=S.epiFooof;
                                catch
                                end
                            end
                        end
                    end
                end
            end
            thpkc=experiment.plot.thetaPeak.ThetaPeaksContainer(thpks,fooof,params);
        end
        function plotThetaSimulation(obj)
            try close(4); catch, end
            figure(4);hold on
            freq(1,:)=linspace(7.7,6.5,10);
            freq(2,:)=linspace(7.5,7.2,10);
            pow(1,:)=linspace(100,600,10);
            pow(2,:)=linspace(100,600,10);
            colorcond=[[0 0 1];[1 0 0]];
            colorcondl=[[0.7 0.7 1];[1 0.7 0.7]];
            t=linspace(-.5,.5,1000);
            for icond=1:2
                subplot(2,1,icond);hold on;
                for iline=1:size(freq,2)
                    y=pow(icond,iline)*sin(2*pi*freq(icond,iline)*t);
                    p=plot(t,y);
                    if iline==1||iline==size(freq,2)
                        p.Color=colorcond(icond,:);
                        %                         p.LineWidth=1.5;
                    else
                        p.Color=colorcondl(icond,:);
                    end
                end
            end
        end
        function pos=getPosition(obj)
            sf=experiment.SessionFactory;
            sest=sf.getSessionsTable;
            sess=sf.getSessions;
            for ises=1:numel(sess)
                ses=sess(ises);
                pos{ises}=ses.getPosition;
                dlfp=ses.getDataLFP;
                sdd=dlfp.getStateDetectionData
            end
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
            %             states=[1 2 3 5];

            for icond=1:numel(conditions)

                try close(icond);catch;end; f=figure(icond);f.Units='normalized';f.Position=[1.0000    0.4391    .7    0.2];
                lastedge=0;
                centers_all=[];
                edges_all=[];
                centers_num=[];
                for iblock=1:size(Conds,2)
                    rcount=Conds(iblock).rCount(:,:,:,icond);
                    scount=Conds(iblock).sCount(:,:,:,icond);
                    scount(scount<seconds(minutes(1)))=nan;
                    rrate=rcount./scount;

                    edges=hours(seconds(Conds(iblock).edges(1,:,1,icond)))+lastedge;
                    lastedge=edges(end);
                    centers=edges(2:end)-(edges(2)-edges(1))/2;
                    %                     centers_all=[centers_all centers] ;
                    %                     edges_all=[edges_all edges] ;
                    %                     centers_num=[centers_num numel(centers)];
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
                    rrateErr=nanstd(rrate,[],3)/sqrt(size(rrate,3));
                    centersall=repmat(centers,size(rratemean,1),1);
                    p=errorbar(centersall', rratemean',rrateErr','-','Marker','.','MarkerSize',20);

                    centershift=([1 2 3 3 4]-2.5)*.05;
                    for iplot=1:numel(p)
                        rrateSes=squeeze(rrate(iplot,:,:));
                        thecolor=colors(iplot,:);
                        plot(centers+centershift(iplot),rrateSes,'Color',thecolor,'LineWidth',.2,'Marker','.','MarkerSize',10,'LineStyle','none')
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
                        text(centers_all(it),-diff(ax.YLim)*.05,strcat(str),'HorizontalAlignment','center');
                        it=it+1;
                    end
                end
                ylabel('SWR rate (#/s)');
                ff=FigureFactory.instance;
                ff.save(strcat('RipleRate_',conditions{icond}));
            end
        end
        function plot_RippleRatesInBlocks_CompareConditions(~,Conds)
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
                    subplot(10,1,1:9);
                    scountmean= squeeze(minutes(seconds(nanmean(scount,2))));
                    yyaxis left
                    b=bar(centers, scountmean','stacked','BarWidth',1,'FaceAlpha',.3);
                    %                     ax.XTick=edges;
                    %                     ax.YLim=[0 obj.Params.Plot.SlidingWindowSizeInMinutes];
                    ylabel('State Duration (min)');
                    xlabel('Time (h)');
                    hold on
                    yyaxis right
                    rratemean=squeeze(nanmean(rrate,2));
                    rrateErr=squeeze(nanstd(rrate,[],2))/sqrt(size(rrate,2));
                    centersall=repmat(centers,size(rratemean,2),1)';
                    p=errorbar(centersall, rratemean,rrateErr,'-','Marker','.','MarkerSize',20);

                    centershift=([0 1]-.5)*.05;
                    for iplot=1:numel(p)
                        rrateSes=squeeze(rrate(:,:,iplot));
                        thecolor=colors(iplot,:);
                        plot(centers+centershift(iplot),rrateSes,'Color',thecolor,'LineWidth',.2,'Marker','.','MarkerSize',10,'LineStyle','none')
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
                        text(centers_all(it),-diff(ax.YLim)*.05,strcat(str),'HorizontalAlignment','center');
                        it=it+1;
                    end
                end
                ylabel('SWR rate (#/s)');
                ff=FigureFactory.instance;
                ff.save(strcat('RipleRate_',statestr{thestate}));
            end
        end
        function plot_FooofInBlocks_CompareConditions(obj,Conds,plotwh)
            s=obj.getParams.Fooof;
            peaksCF=[5 9];%s.BandFrequencies.theta;%
            %             bwth=s.BandWidthThreshold.ripple;
            bwth=[];
            plotwhat={'cf','power','f','offset','k'};

            colors1=linspecer(2,'qualitative');
            colors={colors1(1,:);colors1(2,:)};
            conditions={'NSD','SD'};
            blockstr={'PRE','SD-NSD','TRACK','POST'};
            statelist1=categorical([1 2 3 5],[1 2 3 5],{'AWAKE','QWAKE','SWS','REM'});
            statelist=[1 2 3 5];
            for istate=1:numel(statelist)
                thestate=statelist(istate);
                try close(istate);catch;end; f=figure(istate);f.Units='normalized';f.Position=[1.0000    0.4391    .2    0.2];
                lastedge=0;
                centers_all=[];
                edges_all=[];
                centers_num=[];
                for iblock=1:size(Conds,2)
                    scount=squeeze(Conds(iblock).sCount(thestate,:,:,:));
                    scount(scount<seconds(minutes(1)))=nan;
                    edgesall=squeeze(hours(seconds(Conds(iblock).edges(:,:,:,:))));
                    edgesf=0;
                    for istate1=1:size(edgesall,1)
                        for ises=1:size(edgesall,3)
                            for icond=1:size(edgesall,4)
                                edges1=edgesall(istate1,:,ises,icond);
                                if numel(unique(edges1))>numel(edgesf)
                                    edgesf=edges1;
                                end
                            end
                        end
                    end
                    edges=edgesf+lastedge;
                    lastedge=edges(end);
                    centers=edges(2:end)-(edges(2)-edges(1))/2;
                    if numel(size(scount))>2
                        scountmean= squeeze(minutes(seconds(nanmean(scount,2))));
                    else
                        scountmean= squeeze(minutes(seconds(nanmean(scount,1))));
                    end
                    yyaxis left
                    b=bar(centers, scountmean','stacked','BarWidth',1,'FaceAlpha',.3);
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
                                try
                                    sub_ses_cond.periodic.cf(isub,ises,icond)=fooof.getPeak(peaksCF,[],bwth).cf;
                                catch
                                    sub_ses_cond.periodic.cf(isub,ises,icond)=nan;
                                end
                                try
                                    sub_ses_cond.periodic.power(isub,ises,icond)=fooof.getPeak(peaksCF,[],bwth).power;
                                catch
                                    sub_ses_cond.periodic.power(isub,ises,icond)=nan;
                                end
                                try
                                    sub_ses_cond.periodic.bw(isub,ises,icond)=fooof.getPeak(peaksCF,[],bwth).bw;
                                catch
                                    sub_ses_cond.periodic.bw(isub,ises,icond)=nan;
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
                                try
                                    sub_ses_cond.aperiodic.k(isub,ises,icond)=fooof.fooof_results.aperiodic_params(2);
                                catch
                                    sub_ses_cond.aperiodic.k(isub,ises,icond)=nan;
                                end
                            end
                        end
                    end
                    switch plotwh
                        case {1, 2} %CF power
                            var=sub_ses_cond.periodic.(plotwhat{plotwh});
                        case {3, 4,5} %slope offset
                            var=sub_ses_cond.aperiodic.(plotwhat{plotwh});
                    end

                    clear meanval errval
                    if numel(size(var))>2
                        meanval=squeeze(nanmean(var,2));
                        errval=squeeze(nanstd(var,[],2))/sqrt(size(var,2));
                    else
                        meanval=squeeze(nanmean(var,1));
                        errval=squeeze(nanstd(var,[],1))/sqrt(size(var,2));
                    end
                    centershift=([0 1]-.5)*.2;
                    for iplot=1:2
                        try
                            perrbar=errorbar(centers, meanval(:,iplot),errval(:,iplot),'-','Marker','.','MarkerSize',20);
                        catch
                        end
                        if numel(size(var))>2
                            varSes=squeeze(var(:,:,iplot));
                        else
                            varSes=squeeze(var(:,iplot));
                        end
                        thecolor=colors{iplot};
                        plot(centers+centershift(iplot),varSes,'Color',thecolor,'LineWidth',.2,'Marker','.','MarkerSize',10,'LineStyle','none')
                        clear varSes
                        b(iplot).FaceColor=thecolor;
                        b(iplot).LineWidth=.2;
                        perrbar.Color=thecolor;
                        perrbar.LineWidth=2;
                    end
                end
                legend([b(1) b(2)],conditions,'Location','best')
                title(statelist1(istate));
                ax=gca;
                ax.YColor='k';
                ax.XLim=[0 edges(end)];
                ax.XTick=unique(edges_all);
                it=1;
                for iblock=1:numel(centers_num)
                    for i=1:centers_num(iblock)
                        str=blockstr{iblock};
                        text(centers_all(it),ax.YLim(1)-diff(ax.YLim)*.05,strcat(str),'HorizontalAlignment','center');
                        it=it+1;
                    end
                end
                ff=logistics.FigureFactory.instance('ExperimentSpecific/PlottingRoutines/Printout/fooof');
                switch plotwh
                    case 1 %CF
                        ax.YLim=peaksCF;
                        ylabel('Center Frequency (Hz)');
                        ff.save(strcat('Center Frequency_',char(statelist1(istate))));
                    case 2 %power
                        ax.YLim=[0 1.2];
                        ylabel('Relative Power');
                        ff.save(strcat('Power_',char(statelist1(istate))));
                    case 3 %slope
                        ax.YLim=[1 3];
                        ylabel('F');
                        ff.save(strcat('f_',char(statelist1(istate))));
                    case 4 %offset
                        ax.YLim=[4.5 7.5];
                        ylabel('Offset');
                        ff.save(strcat('Offset_',char(statelist1(istate))));
                    case 5 %offset
                        %                         ax.YLim=[4.5 7.5];
                        ylabel('Knee');
                        ff.save(strcat('Knee_',char(statelist1(istate))));
                end
            end
        end
        function axs=plotEpisode(obj,boc,params,thestate)
            sde=experiment.SDExperiment.instance;
            info=boc.Info;
            subplot(4,4,[1:3 5:7]);ax=gca;
            frange=params.Fooof.f_range;
            [episode, theEpisodeAbs]=boc.getState(thestate);
            thetaFreq=params.BandFrequencies.theta;
            if ~isempty(episode)
                episode1=episode.getDownSampled(50);
                tfm=episode1.getWhitened.getTimeFrequencyMap(...
                    neuro.tf.TimeFrequencyWavelet(logspace(log10(thetaFreq(1)),log10(thetaFreq(2)),100)));
                if ~isempty(tfm.timePoints)
                    tfm.plot;hold on

                    ti=episode1.getTimeIntervalCombined;
                    t=ti.getTimePointsInSamples/ti.getSampleRate;

                    %  calculate ThetaPeak change
                    clear thpk
                    %             episode1=episode.getDownSampled(50);
                    %             tfm1=episode1.getWhitened.getTimeFrequencyMap(...
                    %                 TimeFrequencyWavelet(logspace(log10(thetaFreq(1)),log10(thetaFreq(2)),50)));
                    [thpkcf,thpkpw]=tfm.getFrequencyBandPeak(thetaFreq);
                    %                                             thpk.plot('Color','r');
                    thpkcf_fd=thpkcf.getMedianFiltered(1,'omitnan','truncate').getMeanFiltered(1);
                    thpkcf_fd.plot('Color','k','LineWidth',1.5)
                    ylabel('Frequency (Hz)');
                    xlabel('Time (s)');
                    text(-diff(ax.XLim)*.1,diff(ax.YLim)*.1+ax.YLim(2),  strcat(char(boc.Info.Block),'-',char(info.SubBlock)));

                    t1=text(-diff(ax.XLim)*.14,diff(ax.YLim)*.1+ax.YLim(2),  strcat(sde.getStateCode(double(thestate))));
                    t1.Color=sde.getStateColors(double(thestate));
                    durations1=cumsum(seconds(theEpisodeAbs(:,2)-theEpisodeAbs(:,1)))';
                    durations2=[0 durations1];
                    durationscenter=durations2(1:(numel(durations2)-1))+diff(durations2)/2;
                    for il=1:numel(durations1)
                        l=vline(durations1(il),'w--');
                        l.LineWidth=1;
                        t1=text(durationscenter(il),ax.YLim(2),num2str(il));
                        t1.HorizontalAlignment='center';
                        t1.VerticalAlignment='bottom';
                        t1.Color=sde.getStateColors(double(thestate));
                    end

                    if episode.getLength>minutes(params.Plot.MinDurationInSubBlockMinutes)
                        fooof=episode.getPSpectrumWelch.getFooof(params.Fooof(2),params.Fooof(2).f_range);
                        fooof.Info=episode.Info;
                    else
                        fooof=neuro.power.Fooof();
                    end


                    bands=params.BandFrequencies;
                    bwths=params.BandWidthThreshold;
                    bandsstr=fieldnames(bands);
                    colors=linspecer(numel(bandsstr));
                    for iband=1:numel(bandsstr)
                        bandFreq=bands.(bandsstr{iband});
                        p1=plot([diff(ax.XLim) diff(ax.XLim)]*1,bandFreq);p1.LineWidth=10;p1.Color=colors(iband,:);
                        try
                            bwth=bwths.(bandsstr{iband});
                        catch
                            bwth=[];
                        end
                        try
                            peaks1=fooof.getPeaks(bandFreq,[],bwth);
                            for ipeak=1:numel(peaks1)
                                peak1=peaks1(ipeak);
                                l=yline(peak1.cf);
                                l.LineStyle='--';
                                l.Color='r';
                                if ipeak==1
                                    text(ax.XLim(2)*1.005,peak1.cf,sprintf('%.2f',peak1.cf),'FontSize',12);
                                    l.LineWidth=2;
                                    yline(peak1.cf-peak1.bw/2,'k-');
                                    yline(peak1.cf+peak1.bw/2,'k-');
                                else
                                    text(ax.XLim(2)*1.005,peak1.cf,sprintf('%.2f',peak1.cf),'FontSize',10);
                                end
                            end
                        catch
                        end
                    end
                    axs(1)=ax;
                    subplot(6,4,17:19);hold on;
                    thpkcf.plot('Color','r')
                    thpkcf_fd.plot('Color','k','LineWidth',1.5)

                    for il=1:numel(durations1)
                        l=vline(durations1(il),'k');
                        l.LineWidth=1;
                        t1=text(durationscenter(il),ax.YLim(2),num2str(il));
                        t1.HorizontalAlignment='center';
                        t1.VerticalAlignment='bottom';
                        t1.Color=sde.getStateColors(double(thestate));
                    end

                    bandFreq=bands.theta;
                    p1=plot([diff(ax.XLim) diff(ax.XLim)]*1,bandFreq);p1.LineWidth=10;p1.Color=colors(1,:);
                    ax=gca;
                    peaks1=fooof.getPeaks(bandFreq);
                    if ~isempty(peaks)
                        for ipeak=1:numel(peaks1)
                            peak1=peaks1(ipeak);
                            l=yline(peak1.cf);
                            l.LineStyle='--';
                            l.Color='r';
                            if ipeak==1
                                text(ax.XLim(2)*1.005,peak1.cf,sprintf('%.2f',peak1.cf),'FontSize',12);
                                l.LineWidth=2;
                                yline(peak1.cf-peak1.bw/2,'k-');
                                yline(peak1.cf+peak1.bw/2,'k-');
                            else
                                text(ax.XLim(2)*1.005,peak1.cf,sprintf('%.2f',peak1.cf),'FontSize',10);
                            end
                        end
                    end
                    ax.YLim=thetaFreq;
                    ax.XLim=[0 t(end)];
                    ax.Visible='on';ax.XTick=[];ax.Box='off';
                    ylabel('Freq. (Hz)');
                    text(-diff(ax.XLim)*.075,mean(ax.YLim), '\theta-CF');

                    subplot(6,4,13:15);hold on;
                    thpkpw_fd=thpkpw.getMedianFiltered(1,'omitnan','truncate').getMeanFiltered(1);
                    thpkpw_fd.plot('Color','k','LineWidth',1.5)
                    ylabel('Power');
                    xlabel('Time (s)');
                    ax=gca;ax.YScale='log';
                    hold on;
                    l=yline(nanmean(thpkpw_fd.getValues));l.Color='r';
                end
            end

            hyp=boc.getHypnogram;
            axn=axes;p=ax.Position;
            axn.Position=[p(1) 1-p(4)/3 p(3) p(4)/3];axn.YTick=[];
            if ~isempty(hyp.States)
                hyp.plot
                for ib=1:size(theEpisodeAbs,1)
                    theEpisodeAbsCenters=mean(theEpisodeAbs,2);
                    t1=text(theEpisodeAbsCenters(ib),mean(axn.YLim),num2str(ib));
                    t1.HorizontalAlignment='center';
                end
            end

            if  ~isempty(episode)&&~isempty(tfm.timePoints)
                subplot(6,4,21:23);
                EMG=boc.getChannel(2);
                epiEMG1=EMG.getTimeWindow([theEpisodeAbs(:,1) theEpisodeAbs(:,2)-seconds(1)]);
                l=plot(linspace(0,seconds(epiEMG1.getLength),epiEMG1.getNumberOfPoints),epiEMG1.getValues);hold on;l.LineWidth=2.5;l.Color=colors(3,:);
                l=yline(epiEMG1.getThreshold);l.Color='r';
                ax=gca;
                ax.YLim=[0 1];
                ax.XLim=[0 seconds(epiEMG1.getLength)];
                ax.Visible='on';ax.XTick=[];ax.Box='off';
                ylabel('EMG');

                str=sprintf('%s, %s, %s, ch%d',info.Animal.Code,info.SessionInfo.Date,info.SessionInfo.Condition,episode.getChannelName);
                annotation('textbox',[0 .65 .3 .3],'String',str,'FitBoxToText','on');

                for il=1:numel(durations1)
                    l=vline(durations1(il),'k');
                    l.LineWidth=1;
                    t1=text(durationscenter(il),ax.YLim(2),num2str(il));
                    t1.HorizontalAlignment='center';
                    t1.VerticalAlignment='bottom';
                    t1.Color=sde.getStateColors(double(thestate));
                end


                subplot(3,4,[4 8]);
                try
                    fooof.plot;
                catch
                end
                subplot(3,4,12);
                thpkcf_fd.plotHistogram;
                bandFreq=bands.theta;
                try
                    peaks1=fooof.getPeaks(bandFreq);
                    for ipeak=1:numel(peaks1)
                        peak1=peaks1(ipeak);
                        l=xline(peak1.cf);
                        l.LineStyle='--';
                        l.Color='r';
                        if ipeak==1
                            l.LineWidth=1.5;
                        end
                    end
                    ax=gca;ax.XLim=bandFreq;
                catch
                end


                axn=axes;
                axn.Position=[.6 .8 .5 .25];
                pr1=info.Probe;
                pr=pr1.setActiveChannels(episode.getChannelName);
                pr.plotProbeLayout(episode.getChannelName);
                axn.Visible='off';
            end
        end
    end

 end
