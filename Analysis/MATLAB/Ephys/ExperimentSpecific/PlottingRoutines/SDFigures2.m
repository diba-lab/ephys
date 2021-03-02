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
                                    [rippleRates(thestate).N,rippleRates(thestate).edges] = histcounts( stateRipplePeaksInSeconds,stateRatio.edges); %#ok<AGROW>
                                    rippleRates(thestate).state=thestate; %#ok<AGROW>
                                catch
                                end
                            end
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
                load(cacheFile,'Cond');
            end
            obj.plot_RippleRatesInBlocks_CompareConditions(Cond)
            obj.plot_RippleRatesInBlocks_CompareStates(Cond)
            
        end
        function plotFooof(obj)
            sf=SessionFactory;
            ff=FigureFactory.instance;
            selected_ses=[1 2 3 4 5 6 7 8 9 10 14 15 16 17];
            tses=sf.getSessionsTable(selected_ses);
            sde=SDExperiment.instance;
            sdeparams=sde.get;
            params=obj.getParams.Fooof;
            cacheFile=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache'...
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
                        ss=sdd.getStateSeries;
                        EMG=sdd.getEMG;
                        thId=sdd.getThetaChannelID;
                        blocks=ses.Blocks;
                        blocksStr1=blocks.getBlockNames;
                        blocksStr= blocksStr1([1 2 3 4]);
                        %                         blocksStr= blocksStr1;
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
                            ss_block=ss.getWindow(timeWindowadj);
                            slidingWindowSize=minutes(params.Plot.SlidingWindowSizeInMinutes);
                            edges=0:seconds(slidingWindowSize):seconds(hours(abs(winDuration)));
                            stateRatiosInTime=ss_block.getStateRatios(...
                                seconds(slidingWindowSize),[],edges);
                            subblocks=ss_block.getStartTime+seconds(edges);
                            ctd=ChannelTimeData(file);
                            th=ctd.getChannel(thId);
                            cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache', DataHash(params)...
                                ,strcat(sprintf('PlotFooof_afoof_%s_%d_%s_',cond,isession,block),'.mat'));
                            try
                                load(cacheFilePower,'fooof');
                            catch
                                try
                                    allBlock=th.getTimeWindowForAbsoluteTime(timeWindowadj);
                                    psd1=allBlock.getPSpectrumWelch;
                                    fooof=psd1.getFooof(params.Fooof,params.Fooof.f_range);
                                    %                                 fooof.plot
                                    folder=fileparts(cacheFilePower);if ~isfolder(folder), mkdir(folder); end
                                    save(cacheFilePower,'fooof')
                                catch
                                    fooof=Fooof();
                                end
                            end
                            clear rippleRates;
                            
                            for istate=1:numel(stateRatiosInTime)
                                thestate=stateRatiosInTime(istate).state;
                                if sum(ismember([1 2 3 5],thestate))
                                    cacheFilePower=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache', DataHash(params)...
                                        ,strcat(sprintf('PlotFooof_afoof_%s_%d_%s_%d_',cond,isession,block,istate),'.mat'));
                                    try
                                        load(cacheFilePower,'epiFooof')
                                    catch
                                        clear tfms
                                        for isublock=1:(numel(subblocks)-1)
                                            subblock=subblocks([isublock isublock+1]);
                                            ss_subBlock=ss_block.getWindow(subblock);
                                            try
                                                theEpiso
                                                
                                                deAbs=ss_subBlock.getState(thestate);
                                                episode=th.getTimeWindow(theEpisodeAbs);
                                                fooof=Fooof();
                                                if episode.getLength>minutes(params.Plot.MinDurationInSubBlockMinutes)
                                                    fooof=episode.getPSpectrumWelch.getFooof(params.Fooof,params.Fooof.f_range);
                                                end
                                            catch
                                                fooof=Fooof();
                                            end
                                            epiFooof(isublock)=fooof;
%                                             clear thpk
%                                             cachefilethpk=fullfile(sdeparams.FileLocations.General.PlotFolder,'Cache',DataHash(tses),...
%                                                 strcat(sprintf('PlotFooof_afoof_%s_%d_%s_%d_%d',cond,isession,block,istate,isublock)));
%                                             try
%                                                 load(cachefilethpk,'thpk','episode1');
%                                             catch
                                                    % calculate ThetaPeak change
%                                                     thetaFreq=params.BandFrequencies.theta;
%                                                     episode1=episode.getDownSampled(50);
%                                                 tfm1=episode1.getWhitened.getTimeFrequencyMap(...
%                                                     TimeFrequencyWavelet(logspace(log10(thetaFreq(1)),log10(thetaFreq(2)),50)));
%                                                 thpk=tfm1.getFrequencyBandPeak(thetaFreq);
%                                                 folder=fileparts(cachefilethpk);if ~isfolder(folder), mkdir(folder); end
%                                                 save(cachefilethpk,'thpk','episode1');
%                                             end
                                            %% plot
%                                             try
%                                                 try close; catch, end
%                                                 f=figure('Visible','off');f.Position=[1441,200,2800,1100];
%                                                 subplot(3,4,[1:3 5:7]);ax=gca;
%                                                 frange=params.Fooof.f_range;
%                                                 
%                                                 
%                                                 tfm=episode.getWhitened.getTimeFrequencyMap(...
%                                                     TimeFrequencyWavelet(logspace(log10(frange(1)),log10(frange(2)),100)));
%                                                 tfm.plot;hold on
%                                                 ti=episode1.getTimeIntervalCombined;
%                                                 t=ti.getTimePointsInSamples/ti.getSampleRate;
%                                                 thpk.plot('Color','r');
%                                                 thpk_fd=thpk.getMedianFiltered(1,'omitnan','truncate').getMeanFiltered(1);
%                                                 thpk_fd.plot('Color','k','LineWidth',1.5)
%                                                 
%                                                 ylabel('Frequency (Hz)');
%                                                 xlabel('Time (s)');
%                                                 text(-diff(ax.XLim)*.1,diff(ax.YLim)*2,  strcat(cond,'-',num2str(isublock)));
%                                                 t1=text(-diff(ax.XLim)*.125,diff(ax.YLim)*.05,  strcat(sde.getStateCode(thestate)));
%                                                 t1.Color=sde.getStateColors(istate);
%                                                 durations1=cumsum(seconds(theEpisodeAbs(:,2)-theEpisodeAbs(:,1)))';
%                                                 durations2=[0 durations1];
%                                                 durations=durations2(1:(numel(durations2)-1))+diff(durations2)/2;
%                                                 for il=1:numel(durations1)
%                                                     l=vline(durations1(il),'w-');
%                                                     l.LineWidth=2;
%                                                     t1=text(durations(il),ax.YLim(2),num2str(il));
%                                                     t1.HorizontalAlignment='center';
%                                                     t1.VerticalAlignment='bottom';
%                                                     t1.Color=sde.getStateColors(istate);
%                                                 end
%                                                 bands=params.BandFrequencies;
%                                                 bwths=params.BandWidthThreshold;
%                                                 bandsstr=fieldnames(bands);
%                                                 colors=linspecer(numel(bandsstr));
%                                                 for iband=1:numel(bandsstr)
%                                                     bandFreq=bands.(bandsstr{iband});
%                                                     p1=plot([diff(ax.XLim) diff(ax.XLim)]*1,bandFreq);p1.LineWidth=10;p1.Color=colors(iband,:);
%                                                     try
%                                                         bwth=bwths.(bandsstr{iband});
%                                                     catch
%                                                         bwth=[];
%                                                     end
%                                                     try
%                                                         peaks1=fooof.getPeaks(bandFreq,[],bwth);
%                                                         for ipeak=1:numel(peaks1)
%                                                             peak1=peaks1(ipeak);
%                                                             l=yline(peak1.cf);
%                                                             l.LineStyle='--';
%                                                             l.Color='r';
%                                                             if ipeak==1
%                                                                 text(ax.XLim(2)*1.005,peak1.cf,sprintf('%.2f',peak1.cf),'FontSize',12);
%                                                                 l.LineWidth=2;
%                                                                 yline(peak1.cf-peak1.bw/2,'k-');
%                                                                 yline(peak1.cf+peak1.bw/2,'k-');
%                                                             else
%                                                                 text(ax.XLim(2)*1.005,peak1.cf,sprintf('%.2f',peak1.cf),'FontSize',10);
%                                                             end
%                                                         end
%                                                     catch
%                                                     end
%                                                 end
%                                                 subplot(6,4,17:19);hold on;ax=gca;
%                                                 thpk.plot('Color','r')
%                                                 thpk_fd.plot('Color','k','LineWidth',1.5)
%                                                 bandFreq=bands.theta;
%                                                 try
%                                                     p1=plot([diff(ax.XLim) diff(ax.XLim)]*1,bandFreq);p1.LineWidth=10;p1.Color=colors(1,:);
%                                                     
%                                                     peaks1=fooof.getPeaks(bandFreq);
%                                                     for ipeak=1:numel(peaks1)
%                                                         peak1=peaks1(ipeak);
%                                                         l=yline(peak1.cf);
%                                                         l.LineStyle='--';
%                                                         l.Color='r';
%                                                         if ipeak==1
%                                                             text(ax.XLim(2)*1.005,peak1.cf,sprintf('%.2f',peak1.cf),'FontSize',12);
%                                                             l.LineWidth=2;
%                                                             yline(peak1.cf-peak1.bw/2,'k-');
%                                                             yline(peak1.cf+peak1.bw/2,'k-');
%                                                         else
%                                                             text(ax.XLim(2)*1.005,peak1.cf,sprintf('%.2f',peak1.cf),'FontSize',10);
%                                                         end
%                                                     end
%                                                     ax.YLim=thetaFreq;
%                                                     ax.XLim=[0 t(end)];
%                                                     ax.Visible='on';ax.XTick=[];ax.Box='off';
%                                                     ylabel('Freq. (Hz)');
%                                                     text(-diff(ax.XLim)*.075,mean(ax.YLim), '\theta-CF');
%                                                 catch
%                                                 end
%                                                 try
%                                                     axn=axes;p=ax.Position;
%                                                     axn.Position=[p(1) 1-p(4)/3 p(3) p(4)/3];axn.YTick=[];
%                                                     ss_subBlock.plot
%                                                     for ib=1:size(theEpisodeAbs,1)
%                                                         theEpisodeAbsCenters=mean(theEpisodeAbs,2);
%                                                         t1=text(theEpisodeAbsCenters(ib),mean(axn.YLim),num2str(ib));
%                                                         t1.HorizontalAlignment='center';
%                                                     end
%                                                 catch
%                                                 end
%                                                 try
%                                                     subplot(6,4,21:23);ax=gca;
%                                                     epiEMG1=EMG.getTimeWindow([theEpisodeAbs(:,1) theEpisodeAbs(:,2)-seconds(1)]);
%                                                     epiEMG=epiEMG1.getReSampled(thpk.getTimeStamps);
%                                                     l=epiEMG.plot;hold on;l.LineWidth=2.5;l.Color=colors(3,:);
%                                                     l=yline(epiEMG1.getThreshold);
%                                                     ax.YLim=[0 1];
%                                                     ax.Visible='on';ax.XTick=[];ax.Box='off';
%                                                     ylabel('EMG');
%                                                 catch
%                                                 end
%                                                 str=sprintf('%s, %s, %s, ch%d',ses.Animal.Code,ses.SessionInfo.Date,ses.SessionInfo.Condition,thId);
%                                                 annotation('textbox',[0 .65 .3 .3],'String',str,'FitBoxToText','on');
%                                                 try
%                                                     subplot(3,4,[4 8]);ax=gca;
%                                                     fooof.plot;
%                                                 catch
%                                                 end
%                                                 try
%                                                     subplot(3,4,12);ax=gca;
%                                                     thpk_fd.plotHistogram;
%                                                     bandFreq=bands.theta;
%                                                     try
%                                                         peaks1=fooof.getPeaks(bandFreq);
%                                                         for ipeak=1:numel(peaks1)
%                                                             peak1=peaks1(ipeak);
%                                                             l=xline(peak1.cf);
%                                                             l.LineStyle='--';
%                                                             l.Color='r';
%                                                             if ipeak==1
%                                                                 l.LineWidth=1.5;
%                                                             end
%                                                         end
%                                                     catch
%                                                     end
%                                                 catch
%                                                 end
%                                                 try
%                                                     axn=axes;p=ax.Position;
%                                                     axn.Position=[.2 0 .5 .25];
%                                                     pr1=ses.Probe;
%                                                     pr=pr1.setActiveChannels(thId);
%                                                     pr.plotProbeLayout(thId);
%                                                     axn.Visible='off';
%                                                 catch
%                                                 end
%                                                 fname=strcat(sprintf('/home/ukaya/Desktop/theta-cf/%s/%s/%s/PlotFooof_afoof_%d_%d_%s',block,sde.getStateCode(thestate),cond,isession,isublock),DataHash(params));
%                                                 ff.save(fname);
%                                                 %%Plot end
%                                             catch
%                                             end
                                        end
                                        folder=fileparts(cacheFilePower);
                                        if ~isfolder(folder), mkdir(folder); end
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
                save(cacheFile,'Cond');
            else
                load(cacheFile,'Cond');
            end
            obj.plot_FooofInBlocks_CompareConditions(Cond)
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
        function plot_FooofInBlocks_CompareConditions(obj,Conds,param)
            s=obj.getParams.Fooof;
            peaksCF=s.BandFrequencies.theta;
            colors1=linspecer(2,'qualitative');
            colors={colors1(1,:);colors1(2,:)};
            conditions={'NSD','SD'};
            blockstr={'PRE','SD-NSD','TRACK','POST'};
            states=[1 2 3 5];
            statestr={'A-WAKE','Q-WAKE','SWS','all','REM'};
            ff=FigureFactory.instance;
            for thestate=states
                try close(thestate);catch;end; f=figure(thestate);f.Units='normalized';f.Position=[1.0000    0.4391    .2    0.2];
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
                                try
                                    sub_ses_cond.aperiodic.k(isub,ises,icond)=fooof.fooof_results.aperiodic_params(2);
                                catch
                                    sub_ses_cond.aperiodic.k(isub,ises,icond)=nan;
                                end
                                
                            end
                        end
                    end
                                        var=sub_ses_cond.thetaPeak.cf;
%                     var=sub_ses_cond.thetaPeak.power;
                    %                     var=sub_ses_cond.aperiodic.f;
                    %                     var=sub_ses_cond.aperiodic.offset;
                    meanval=squeeze(nanmean(var,2));
                    errval=squeeze(nanstd(var,[],2))/sqrt(size(var,2));
                    centers2=repmat(centers,size(meanval,2),1)';
                    perrbar=errorbar(centers2, meanval,errval,'-','Marker','.','MarkerSize',20);
                    clear meanval, errval
                    centershift=([0 1]-.5)*.05;
                    for iplot=1:numel(perrbar)
                        varSes=squeeze(var(:,:,iplot));
                        thecolor=colors{iplot};
                        plot(centers+centershift(iplot),varSes,'Color',thecolor,'LineWidth',.2,'Marker','.','MarkerSize',10,'LineStyle','none')
                        clear varSes
                        b(iplot).FaceColor=thecolor;
                        b(iplot).LineWidth=.2;
                        perrbar(iplot).Color=thecolor;
                        perrbar(iplot).LineWidth=2;
                    end
                end
                legend([b(1) b(2)],conditions,'Location','best')
                title(statestr{thestate});
                ax=gca;
                ax.YColor='k';
                ax.YLim=peaksCF;%CF
%                 ax.YLim=[.1 1.4];%power
                %                 ax.YLim=[1 2.5];%slope
                %                 ax.YLim=[4.5 7.5];%offset
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
                ylabel('Center Frequency (Hz)');
%                 ylabel('Relative Power');
%                 ylabel('F');
%                 ylabel('Offset');
                ff=FigureFactory.instance;
                ff.save(strcat('Center Frequency_',statestr{thestate}));
%                 ff.save(strcat('Power_',statestr{thestate}));
%                 ff.save(strcat('f_',statestr{thestate}));
%                 ff.save(strcat('Offset_',statestr{thestate}));
            end
        end
    end
    
end
