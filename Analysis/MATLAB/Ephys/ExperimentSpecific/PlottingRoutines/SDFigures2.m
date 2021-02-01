classdef SDFigures2 <Singleton
    %FIGURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Sessions
        Params
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
            configureFile=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','SWRRate.xml');
            try
                S=readstruct(configureFile);
            catch
                S.Blocks.PRE=-3;
                S.Blocks.SD=5;
                S.Blocks.TRACK=1;
                S.Blocks.POST=3;
                S.Plot.SlidingWindowSizeInMinutes=30;
                S.Plot.SlidingWindowLapsInMinutes=30;
                writestruct(S,configureFile)
            end
            structstruct(S);
            obj.Params=S;
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
        function plotSWRRate(obj)
            sf=SessionFactory;
            selected_ses=[1 2 3 4 5 6 14 15 16 17];
            tses=sf.getSessionsTable(selected_ses);
            sde=SDExperiment.instance.get;
            cacheFile=fullfile(sde.FileLocations.General.PlotFolder,'Cache',strcat('PlotSWRRate_',DataHash(tses),'.mat'));
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
                            winDuration=obj.Params.Blocks.(block);
                            if winDuration>0
                                timeWindow=[timeWindow(1) timeWindow(1)+hours(winDuration)];
                            else
                                timeWindow=[timeWindow(2)+hours(winDuration) timeWindow(2)];
                            end
                            ss=sdd.getStateSeries;
                            ss_block=ss.getWindow(timeWindow);
                            slidingWindowSize=minutes(obj.Params.Plot.SlidingWindowSizeInMinutes);
                            slidingWindowLaps=minutes(obj.Params.Plot.SlidingWindowLapsInMinutes);
                            edges=0:seconds(slidingWindowSize):seconds(hours(abs(winDuration)));
                            stateRatiosInTime=ss_block.getStateRatios(...
                                seconds(slidingWindowSize),[],edges);
                            
                            bc=BuzcodeFactory.getBuzcode(file);
                            ripple=bc.calculateSWR;
                            ripple_block=ripple.getWindow(timeWindow);
                            
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
                                    Cond(icond,iblock).sratio(thestate,:,isession)=stateRatiosInTime(thestate).Ratios;
                                    Cond(icond,iblock).sCount(thestate,:,isession)=stateRatiosInTime(thestate).N;
                                    Cond(icond,iblock).rCount(thestate,:,isession)=rippleRates(thestate).N;
                                    Cond(icond,iblock).edges(thestate,:,isession)=rippleRates(thestate).edges;
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
            obj.plot_RippleRatesInBlocks_StatesSeparated(Cond)
            
        end
        function plot_RippleRatesInBlocks_StatesSeparated(obj,Conds)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            colorsall=linspecer(10,'sequential');
            colors=colorsall([10 8 1 5 3],:);
            conditions={'NSD','SD'};
            for icond=1:size(Conds,1)
                try close(icond);catch;end; f=figure(icond);f.Units='normalized';f.Position=[1.0000    0.4391    1.4    0.2];
                lastedge=0;
                for iblock=1:size(Conds,2)
                    rcount=Conds(icond,iblock).rCount;
                    scount=Conds(icond,iblock).sCount;
                    scount(scount<seconds(minutes(1)))=nan;
                    rrate=rcount./scount;
                    %                 sratio=Conds(icond).sratio;
                    edges=hours(seconds(Conds(icond,iblock).edges(1,:,1)))+lastedge;
                    lastedge=edges(end);
                    centers=edges(2:end)-(edges(2)-edges(1))/2;
                    
                    subplot(10,1,1:9);
                    scountmean= minutes(seconds(nanmean(scount,3)));
                    yyaxis left
                    b=bar(centers, scountmean','stacked','BarWidth',1,'FaceAlpha',.3);
                    ax=gca;
%                     ax.XTick=edges;
                    ax.YLim=[0 obj.Params.Plot.SlidingWindowSizeInMinutes];
                    ylabel('State Duration (min)');
                    xlabel('Time (h)');
                    hold on
                    yyaxis right
                    rratemean=nanmean(rrate,3);
                    rrateErr=nanstd(rrate,[],3)/sqrt(size(rrate,3));
                    centersall=repmat(centers,size(rratemean,1),1);
                    p=errorbar(centersall', rratemean',rrateErr','-','Marker','.','MarkerSize',20);
                    
                    centershift=([1 2 3 3 4]-4)*.05;
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
                ax.XLim=[0 12.35];
                pre=1:3;sd=(1:5)+pre(end); track=[1/3 2/3 3/3 4/3]+sd(end);post=(1:3)+track(end);
                ax.XTick=[0 pre sd  track post];
                ax.XTickLabel='|';
                XTickLabel(1:3)={'PRE1','PRE2','PRE3'};
                XTickLabel(4:8)={'SD1','SD2','SD3','SD4','SD5'};
                XTickLabel(9:12)={'Tq1','Tq2','Tq3','Tq4'};
                XTickLabel(13:15)={'POST1','POST2','POST3'};
                for ixtick=1:numel(XTickLabel)
                    xtick=ax.XTick([ixtick ixtick+1]);
                    text(mean(xtick),-diff(ax.YLim)*.05,XTickLabel(ixtick),'HorizontalAlignment','center');
                end
                ylabel('SWR rate (#/s)');
                ff=FigureFactory.instance;
                ff.save(strcat('RipleRate_',conditions{icond}));
            end
            
        end
        
    end
end


