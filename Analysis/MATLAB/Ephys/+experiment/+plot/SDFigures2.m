classdef SDFigures2 <Singleton
    %FIGURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Sessions
    end
    
    methods(Access=private)
        function obj = SDFigures2()
            % Initialise your custom properties.
            sf=SessionFactory;
            obj.Sessions= sf.getSessions();
            sde=SDExperiment.instance.get;
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
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = SDFigures2();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        function S=getParams(~)
            sde=SDExperiment.instance.get;
            configureFileSWRRate=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','SWRRate.xml');
            S.SWRRate=readstruct(configureFileSWRRate);
            configureFileFooof=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','Fooof.xml');
            S.Fooof=readstruct(configureFileFooof);
            
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
                                    [rippleRates(thestate).N,rippleRates(thestate).edges] = ...
                                        histcounts( stateRipplePeaksInSeconds,stateRatio.edges); %#ok<AGROW>
                                    rippleRates(thestate).state=thestate; %#ok<AGROW>
                                catch
                                end
                            end
                            for istate=1:numel(stateRatiosInTime)
                                thestate=stateRatiosInTime(istate).state;
                                
                                if sum(ismember([1 2 3 5],thestate))
                                    Cond(iblock).sratio(thestate,:,isession,icond)=stateRatiosInTime(thestate).Ratios; %#ok<AGROW>
                                    Cond(iblock).sCount(thestate,:,isession,icond)=stateRatiosInTime(thestate).N; %#ok<AGROW>
                                    Cond(iblock).rCount(thestate,:,isession,icond)=rippleRates(thestate).N; %#ok<AGROW>
                                    Cond(iblock).edges(thestate,:,isession,icond)=rippleRates(thestate).edges; %#ok<AGROW>
                                end
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
            obj.plot_RippleRatesInBlocks_CompareConditions(Cond)
            obj.plot_RippleRatesInBlocks_CompareStates(Cond)
            
        end
        function plotFooof(obj,plotwh)
            if ~exist('plotwh','var')
                plotwh=1;
            end
            sf=SessionFactory;
            selected_ses=[1 2 3 4 5 6 7 8 9 10 11 14 15 16 17];
            tses=sf.getSessionsTable(selected_ses);
            sde=SDExperiment.instance;
            sdeparams=sde.get;
            params=obj.getParams.Fooof;
            cacheFile=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache'...
                ,strcat('PlotFooof_',DataHash(tses), DataHash(params),'.mat'));
            conditions=categorical(tses.Condition);
            conditionsCat=categories(conditions);
            clear Cond
            if ~isfile(cacheFile)
                
                for icond=1:numel(conditionsCat)
                    cond=conditionsCat(icond);
                    filepath=tses.Filepath(  ismember(conditions,cond));
                    cond=unique(conditions(ismember(conditions,cond)));
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
                        sdd=StateDetectionData(file);
                        sdd.Info.SessionInfo=ses.SessionInfo;
                        EMG=sdd.getEMG;
                        ss=sdd.getStateSeries;
                        thId=sdd.getThetaChannelID;
                        ctd=neuro.basic.ChannelTimeDataHard(file);
                        th=ctd.getChannel(thId);
                        blocks=ses.Blocks;
                        blocksStr1=categorical([1 2 3 4],[1 2 3 4],blocks.getBlockNames,'Ordinal',true);
                        blocksStr= blocksStr1([1 2 3 4]);
                        %                         blocksStr= blocksStr1;
                        for iblock=1:numel(blocksStr)
                            boc=BlockOfChannels();
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
                            try
                                emg=EMG.getTimeWindow(timeWindowadj);
                            catch
                            end
                            boc=boc.addChannel(emg);
                            ss_block=ss.getWindow(timeWindowadj);
                            boc=boc.addHypnogram(ss_block);
                            slidingWindowSize=minutes(params.Plot.SlidingWindowSizeInMinutes);
                            edges=0:seconds(slidingWindowSize):seconds(hours(abs(winDuration)));
                            %                             cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache', DataHash(params)...
                            %                                 ,strcat(sprintf('PlotFooof_afoof_%s_%d_%s_',cond,isession,block),'.mat'));
                            %                             try
                            %                                 load(cacheFilePower,'fooof');
                            %                             catch
                            %                                 try
                            %                                     psd1=allBlock.getPSpectrumWelch;
                            %                                     fooof=psd1.getFooof(params.Fooof(1),params.Fooof(1).f_range);
                            %                                     %                                     fooof.plot
                            %                                     folder=fileparts(cacheFilePower);if ~isfolder(folder), mkdir(folder); end
                            %                                     save(cacheFilePower,'fooof')
                            %                                 catch
                            %                                     fooof=Fooof();
                            %                                 end
                            %                             end
                            stateRatiosInTime=boc.getStateRatios(...
                                seconds(slidingWindowSize),[],edges);
                            statelist=categorical(stateRatiosInTime.getStateList,[1 2 3 5],{'AWAKE','QWAKE','SWS','REM'});
                            statelistnum=stateRatiosInTime.getStateList;
                            for istate=1:numel(statelist)
                                thestate=statelist(istate);
                                thestateNum=statelistnum(istate);
                                cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache', DataHash(params)...
                                    ,strcat(sprintf('PlotFooof_afoof_%s_%d_%s_%s_',cond,isession,block,thestate),'.mat'));
                                try
                                    load(cacheFilePower,'thpks','epiFooof')
                                catch
                                    clear tfms thpks epiFooof
                                    subblocks=boc.getStartTime+seconds(edges);
                                    for isublock=1:(numel(subblocks)-1)
                                        subblock=subblocks([isublock isublock+1]);
                                        try
                                            boc_sub=boc.getWindow(subblock);
                                        catch
                                            boc_sub=[];
                                        end
                                        fooof=Fooof();
                                        thpk=ThetaPeak();
                                        if ~isempty(boc_sub)
                                            boc_sub.Info.SubBlock=categorical(isublock,1:(numel(subblocks)-1));
                                            try
                                                episode=boc_sub.getState(thestateNum);
                                            catch
                                            end
                                            if ~isempty(episode) && (episode.getLength>minutes(params.Plot.MinDurationInSubBlockMinutes))
                                                fooof=episode.getPSpectrumWelch.getFooof(params.Fooof(2),params.Fooof(2).f_range);
                                                fooof.Info=episode.Info;
                                                
                                                thetaFreq=params.BandFrequencies.theta;
                                                episode1=episode.getDownSampled(50);
                                                thpk=episode1.getFrequencyBandPeak(thetaFreq);
                                                thpk=thpk.addFooof(fooof);
                                            end
                                        end
                                        epiFooof(isublock)=fooof; %#ok<AGROW>
                                        try
                                            thpks=thpks+thpk;
                                        catch
                                            thpks=thpk;
                                        end
                                        
                                        %                                         try
                                        %                                             try close; catch, end
                                        %                                             f=figure('Visible','on');f.Position=[1441,200,2800,1100];
                                        %
                                        %                                             obj.plotEpisode(boc_sub,params,statelist(1));%awake
                                        %
                                        %                                             fname=strcat(sprintf('/home/ukaya/Desktop/theta-cf/%s/%s/%s/PlotFooof_afoof_%d_%d_%s',block,sde.getStateCode(thestate),cond,isession,isublock),DataHash(params));
                                        %                                             ff.save(fname);
                                        %                                             %Plot end
                                        %                                         catch
                                        %                                         end
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
                                    Cond(iblock).fooof(stt,:,isession,icond)=Fooof(); %#ok<AGROW>
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
        function plotDist(obj)
            sde=SDExperiment.instance;
            sdeparams=sde.get;
            params=obj.getParams.Fooof;
            
            ff=FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout/fooof');
            
            statelist=categorical({'AWAKE','QWAKE','SWS','REM'});
            condlist=categorical({'NSD','SD'});
            blocklist=categorical({'PRE','NSD','SD','TRACK','POST'});
            
            conds=condlist(1:2);
            blocks=blocklist(2:3);
            sesnos=1:8;
            states=statelist(1);
            try close(10); catch, end;
            for icond=1:numel(conds)
                cond=conds(icond);
                try close(double(cond)+6); catch, end; f=figure(double(cond)+6);f.Position=[1,2,700,1200];
                for isession=1:numel(sesnos)
                    session=sesnos(isession);
                    for iblock=1:numel(blocks)
                        block=blocks(iblock);
                        for istate=1:numel(states)
                            state=states(istate);
                            cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache', DataHash(params)...
                                ,strcat(sprintf('PlotFooof_afoof_%s_%d_%s_%s_',cond,session,block,state),'.mat'));
                            if isfile(cacheFilePower)
                                load(cacheFilePower,'thpks','epiFooof')
                                thpks.plotCF(numel(sesnos),isession);
                                if exist('thpksm','var')
                                    thpksm=thpksm.merge(thpks);
                                else
                                    thpksm=thpks;
                                end
                                clear thpks
                            end
                            
                        end
                    end
                end
                txt=sprintf('ThetaPeak_dist_%s_%s_%s_',cond,block,state);
                ff.save(txt)
                f=figure(10);f.Position=[2096,1844,900,200];
                if exist('axs','var')
                    axs=thpksm.plotCF(axs);
                else
                    axs=thpksm.plotCF();
                end
                clear thpksm
            end
            txt=sprintf('ThetaPeak_dist_Comparison_%s_%s_',block,state);
            ff.save(txt);
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
                        perrbar=errorbar(centers, meanval(:,iplot),errval(:,iplot),'-','Marker','.','MarkerSize',20);
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
                ff=FigureFactory.instance;
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
            sde=SDExperiment.instance;
            info=boc.Info;
            subplot(3,4,[1:3 5:7]);ax=gca;
            frange=params.Fooof.f_range;
            [episode, theEpisodeAbs]=boc.getState(thestate);
            thetaFreq=params.BandFrequencies.theta;
            
            episode1=episode.getDownSampled(50);
            tfm=episode1.getWhitened.getTimeFrequencyMap(...
                TimeFrequencyWavelet(logspace(log10(thetaFreq(1)),log10(thetaFreq(2)),100)));
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
            try text(-diff(ax.XLim)*.1,diff(ax.YLim)*2,  strcat(char(info.Condition),'-',char(info.SubBlock)));
            catch,end
            try t1=text(-diff(ax.XLim)*.125,diff(ax.YLim)*.05,  strcat(sde.getStateCode(double(thestate))));
                t1.Color=sde.getStateColors(double(thestate));
            catch
            end
            durations1=cumsum(seconds(theEpisodeAbs(:,2)-theEpisodeAbs(:,1)))';
            durations2=[0 durations1];
            durations=durations2(1:(numel(durations2)-1))+diff(durations2)/2;
            for il=1:numel(durations1)
                l=vline(durations1(il),'w--');
                l.LineWidth=1;
                t1=text(durations(il),ax.YLim(2),num2str(il));
                t1.HorizontalAlignment='center';
                t1.VerticalAlignment='bottom';
                t1.Color=sde.getStateColors(double(thestate));
            end
            
            if episode.getLength>minutes(params.Plot.MinDurationInSubBlockMinutes)
                fooof=episode.getPSpectrumWelch.getFooof(params.Fooof(2),params.Fooof(2).f_range);
                fooof.Info=episode.Info;
            else
                fooof=Fooof();
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
            subplot(6,4,17:19);hold on;ax=gca;
            thpkcf.plot('Color','r')
            thpkcf_fd.plot('Color','k','LineWidth',1.5)
            
            %             yyaxis right
            %             thpkpw_fd=thpkpw.getMedianFiltered(1,'omitnan','truncate').getMeanFiltered(1);
            %             thpkpw_fd.plot('Color','k','LineWidth',1.5)
            %             ylabel('Power');
            %             xlabel('Time (s)');
            %             ax=gca;ax.YScale='log';
            %             hold on;
            %             yline(mean(thpkpw_fd.getValues))
            
            bandFreq=bands.theta;
            try
                p1=plot([diff(ax.XLim) diff(ax.XLim)]*1,bandFreq);p1.LineWidth=10;p1.Color=colors(1,:);
                
                peaks1=fooof.getPeaks(bandFreq);
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
                ax.YLim=thetaFreq;
                ax.XLim=[0 t(end)];
                ax.Visible='on';ax.XTick=[];ax.Box='off';
                ylabel('Freq. (Hz)');
                text(-diff(ax.XLim)*.075,mean(ax.YLim), '\theta-CF');
            catch
            end
            try
                hyp=boc.getHypnogram;
                axn=axes;p=ax.Position;
                axn.Position=[p(1) 1-p(4)/3 p(3) p(4)/3];axn.YTick=[];
                hyp.plot
                for ib=1:size(theEpisodeAbs,1)
                    theEpisodeAbsCenters=mean(theEpisodeAbs,2);
                    t1=text(theEpisodeAbsCenters(ib),mean(axn.YLim),num2str(ib));
                    t1.HorizontalAlignment='center';
                end
            catch
            end
            try
                subplot(6,4,21:23);ax=gca;
                EMG=boc.getChannel(2);
                epiEMG1=EMG.getTimeWindow([theEpisodeAbs(:,1) theEpisodeAbs(:,2)-seconds(1)]);
                epiEMG=epiEMG1.getReSampled(thpkcf.getTimeStamps);
                l=epiEMG.plot;hold on;l.LineWidth=2.5;l.Color=colors(3,:);
                l=yline(epiEMG1.getThreshold);
                ax.YLim=[0 1];
                ax.Visible='on';ax.XTick=[];ax.Box='off';
                ylabel('EMG');
            catch
            end
            str=sprintf('%s, %s, %s, ch%d',info.Animal.Code,info.SessionInfo.Date,info.SessionInfo.Condition,episode.getChannelName);
            annotation('textbox',[0 .65 .3 .3],'String',str,'FitBoxToText','on');
            try
                subplot(3,4,[4 8]);ax=gca;
                fooof.plot;
            catch
            end
            try
                subplot(3,4,12);ax=gca;
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
                    ax.XLim=bandFreq;
                catch
                end
            catch
            end
            
            try
                axn=axes;p=ax.Position;
                axn.Position=[.2 0 .5 .25];
                pr1=info.Probe;
                pr=pr1.setActiveChannels(episode.getChannelName);
                pr.plotProbeLayout(episode.getChannelName);
                axn.Visible='off';
            catch
            end
        end
    end
    
end
