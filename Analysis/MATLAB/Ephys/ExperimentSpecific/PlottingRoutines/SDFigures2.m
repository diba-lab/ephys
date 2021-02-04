classdef SDFigures2 <Singleton
    %FIGURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Sessions
    end
    
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
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
        function S=getParams(obj)
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
            obj.plot_RippleRatesInBlocks_CompareStates(Cond)
            obj.plot_RippleRatesInBlocks_CompareConditions(Cond)
            
        end
        function plotFooof(obj)
            sf=SessionFactory;
            selected_ses=[1 2 3 4 5 6 7 8 9 10 14 15 16 17];
            tses=sf.getSessionsTable(selected_ses);
            sde=SDExperiment.instance.get;
            params=obj.getParams.Fooof;
            cacheFile=fullfile(sde.FileLocations.General.PlotFolder,'Cache'...
                ,strcat('PlotFooof_',DataHash(tses), DataHash(params),'.mat'));
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
                            
                            thId=sdd.getThetaChannelID;
                            ctd=ChannelTimeData(file);
                            th=ctd.getChannel(thId);
                            allBlock=th.getTimeWindowForAbsoluteTime(timeWindowadj);
                            cacheFilePower=fullfile(sde.FileLocations.General.PlotFolder,'Cache'...
                                ,strcat('PlotFooof_afoof_',DataHash(tses), DataHash(params), DataHash(timeWindowadj),'.mat'));
                            try
                                load(cacheFilePower,'fooof');
                            catch
                                psd1=allBlock.getPSpectrumWelch;
                                fooof=psd1.getFooof(params.Fooof,params.Fooof.f_range);
                                save(cacheFilePower,'fooof')
                            end
                            stateEpisodes=ss_block.getEpisodes;
                            stateNames=ss_block.getStateNames;
                            clear rippleRates;
                            for istate=1:numel(stateRatiosInTime)
                                
                                thestate=stateRatiosInTime(istate).state;
                                stateRatio=stateRatiosInTime(thestate);
                                try
                                    theStateName=stateNames{istate};
                                    theEpisode=stateEpisodes.(strcat(theStateName,'state'));
                                    ticdss=ss_block.TimeIntervalCombined;
                                    theEpisodeAbs=ticdss.getRealTimeFor(theEpisode);
                                    episode=allBlock.getTimeWindow(theEpisodeAbs);
                                    epiFooof=episode.getPSpectrumWelch.getFooof(settings,f_range);
                                    epiFooof.plot
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
        function plot_RippleRatesInBlocks_CompareConditions(obj,Conds)
            s=obj.getParams;
            params=s.SWRRate;
            colorsall=linspecer(10,'sequential');
            colors=colorsall([1 10 1 5 3],:);
            conditions={'NSD','SD'};
            blockstr={'PRE','SD/NSD','TRACK','POST'};
            states=[1 2 3 5];
            statestr={'A-WAKE','Q-WAKE','SWS','REM'};
            for thestate=states
                try close(thestate);catch;end; f=figure(thestate);f.Units='normalized';f.Position=[1.0000    0.4391    1.4    0.2];
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
                    
                    
                    
                    
                    edges=hours(seconds(Conds(iblock).edges(thestate,:,1,1)))+lastedge;
                    if numel(unique(edges))<numel(edges)
                        edges=hours(seconds(Conds(iblock).edges(thestate,:,1,2)))+lastedge;
                    end
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
                        plot(centers+centershift(iplot),rrateSes,'Color',thecolor,'LineWidth',.2,'Marker','.','MarkerSize',10,'LineStyle','none')
                        b(iplot).FaceColor=thecolor;
                        b(iplot).LineWidth=.2;
                        p(iplot).Color=thecolor;
                        p(iplot).LineWidth=2;
                    end
                end
                legend([b(1) b(2)],{'NSD','SD'},'Location','best')
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
    end
    
end
