classdef FiguresUnitFireRate < experiment.plot.unit.FiguresUnit
    %FIGURESUNITFIRERATE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Injections
    end
    
    methods
        function obj = FiguresUnitFireRate()
            %FIGURESUNITFIRERATE Construct an instance of this class
            %   Detailed explanation goes here
            obj.Injections=[1 2.5];
        end
        
        function plotFireRateQui(obj)
            figureFolder='./ExperimentSpecific/PlottingRoutines/UnitPlots/figures';
            if ~isfolder(figureFolder), mkdir(figureFolder);end
            ff=logistics.FigureFactory.instance(figureFolder);
            sessions=obj.SpikeArrays;
            fireratechannels=1:2:10;
            %             fireratechannels=11:2:14;
            names={'q1','q2','q3','q4','q5'};
            %             names={'mua','int'};
            smoothfactor=obj.getParameters.fireRatePlotSmoothingFactor;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessionsNos=obj.getSessionNos;
            for ises=1:numel(sessionsNos)
                sublist=list(list.SESSIONNO==sessionsNos(ises),:);
                %                 inj=unique(sublist.INJECTION);
                ani=unique(sublist.ANIMAL);
                %                 sessionsstr(ises)=inj; %#ok<AGROW>
                legendstr(ises)=strcat(ani,'__',unique(sublist.SLEEP)); %#ok<AGROW>
            end
            try close(1); catch, end; f=figure(1);f.Position=[1,1,2560/2,1348];
            for ises=1:numel(sessions)
                sesno=sessionsNos(ises);
                blnames=obj.getBlock(sesno).getBlockNames;
                %                 blint=4;blnames=blnames(blint);%ALL BLOCKS
                clear axp axh
                for ibl=1:numel(blnames)
                    aBlockBOC=obj.getBlockOfChannels(sesno,blnames{ibl});
                    if ~exist('axp','var')
                        subplot(numel(sessions),1,ises);
                        [axp,axh,ps]=aBlockBOC.plot([],[],fireratechannels,smoothfactor);hold on;
                        axes(axp);
                        grid on
                        try
                            aBlockBOC.plotStatewise(axp,axh,fireratechannels,smoothfactor);hold on;
                        catch
                        end
                    else
                        [axp,axh,ps]=aBlockBOC.plot(axp,axh,fireratechannels,smoothfactor);hold on;
                        try
                            aBlockBOC.plotStatewise(axp,axh,fireratechannels,smoothfactor);hold on;
                        catch
                        end
                    end
                    bocs{ibl}=aBlockBOC;
                end
                axp.YScale='log';
                axp.YLim=[1e-4 1e2];
                %                 xlim=[bocs{1}.getStartTime bocs{4}.getEndTime]; %ALL BLOCKS
                xlim=duration({'5:00','18:00'},'InputFormat','hh:mm')+bocs{1}.getDate; %ALL BLOCKS FIXED
                %                 xlim=[bocs{1}.getStartTime bocs{1}.getEndTime];%INTERESTED BLOCKS
                axp.XLim=xlim;
                axh.XLim=xlim;
                sesnos=obj.getSessionNos;
                axes(axp);
                %                 obj.addInjections(sesnos(ises));
                ylabel('Firing Rate (Hz)');
                title(legendstr{ises})
                legend(ps,names);
            end
            ylabel('Fire Rate (Hz)');
            %             ff.save(strcat('allblocks_',blnames{ibl}));%INTERESTED BLOCKS
            ff.save('allblocksstatewise');%ALL BLOCKS
            %             ff.save('allblocksfixed');%ALL BLOCKS
        end
        function plotFireRate(obj)
            figureFolder='./ExperimentSpecific/PlottingRoutines/UnitPlots/figures';
            if ~isfolder(figureFolder), mkdir(figureFolder);end
            ff=logistics.FigureFactory.instance(figureFolder);
            sessions=obj.SpikeArrays;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessionsNos=obj.getSessionNos;
            for ises=1:numel(sessionsNos)
                sublist=list(list.SESSIONNO==sessionsNos(ises),:);
                %                 inj=unique(sublist.INJECTION);
                ani=unique(sublist.ANIMAL);
                %                 sessionsstr(ises)=inj; %#ok<AGROW>
                legendstr(ises)=strcat(ani,', ',unique(sublist.SLEEP)); %#ok<AGROW>
            end
            for ises=3:numel(sessions)
                sesno=sessionsNos(ises);
                blnames=obj.getBlock(sesno).getBlockNames;
                frs=obj.getFireRates(sesno);
                %                 blint=4;blnames=blnames(blint);%ALL BLOCKS
                locs=unique(frs.ClusterInfo.location);
                for iloc=1:numel(locs)
                    loc=locs{iloc};
                    frssub(iloc)=frs.get(ismember(frs.ClusterInfo.location,loc));
                    sizes(iloc)=size(frssub(iloc).Data,1);
                end
                try close(1); catch, end; f=figure(1);f.Position=[100,100,2560*.5,1348*.5];
                xlim=duration({'5:00','18:00'},'InputFormat','hh:mm')+frs.Time.getDate; %ALL BLOCKS FIXED
                xlim1=hours(xlim-frs.Time.getDatetime("08:00"));
                axp=axes;
                axps(1)=axp;
                ha=axp.Position(4);
                for iloc=1:numel(locs)
                    if iloc>1
                        hs=ha*sizes(iloc)/sum(sizes);
                        axp.Position(2)=axp.Position(2)+hs;
                        axp=axes;
                        axps(iloc)=axp;
                    else
                        hs=ha*sizes(iloc)/sum(sizes);
                    end
                    axp.Position=[axp.Position(1) axp.Position(2) axp.Position(3) hs];
                    frs=frssub(iloc);
                    frs.plotFireRates;
                    if iloc>1, colorbar off;end
                    ylabel(locs{iloc});
                    axp.XLim=xlim1;
                    axp.CLim=[-.5 2];
                end
                hypno=frs.Info.hypnogram;
                axh=axes;
                axh.Position=[axp.Position(1) axp.Position(2)+ha*1.01 axp.Position(3) .04];
                ps=hypno.plot;
                l=legend(ps([1 2 3 5]),{'a-Wake','q-Wake','SWS','REM'},'Location','none');
                l.Position=[.92 .93 .05 .05];
                axh.XLim=xlim;
                axh.Box='off';
                axh.XAxisLocation='top';
                axh.YTickLabel=[];
                
                params=obj.getParameters;
                interestedBlocks=fieldnames(params.interest);
                axes(axp);
                a=annotation('textbox', [.4 .02 .2 .04], 'String','','FitBoxToText','on');
                label1=sprintf('%s',legendstr{ises});
                a.String=label1;
                ff.save(['ses_' num2str(sesno) '_' label1]);
                %%
                %                 for iblock=1:numel(interestedBlocks)
                %                     block=interestedBlocks{iblock};
                %                     block_times=obj.getBlockTimes(sesno,block);
                %
                %                     wins=params.interest.(block);
                %                     for iwin=1:numel(wins)
                %                         st1=hours(wins(iwin).st);
                %                         if st1<0
                %                             st=block_times(2)+st1;
                %                         else
                %                             st=block_times(1)+st1;
                %                         end
                %                         dur=minutes(wins(iwin).dur);
                %                         en=st+dur;
                %                         if st>en, tmp=st; st=en;en=tmp;end
                %                         win=[st en];
                %                         xlim=win+frs.Time.getDate; %ALL BLOCKS FIXED
                %                         xlim1=hours(xlim-frs.Time.getDatetime("08:00"));
                %                         for iloc=1:numel(locs)
                %                             axps(iloc).XLim=xlim1;
                %                         end
                %                         axh.XLim=xlim;
                %                         label1=sprintf('%s, %s, <%s, %s>',legendstr{ises},block,string(st1),string(dur));
                %                         a.String=label1;
                %                         ff.save(['ses_' num2str(sesno) '_' label1]);
                %                     end
                %                 end
                %%
                xlim=duration({'5:00','18:00'},'InputFormat','hh:mm')+frs.Time.getDate; %ALL BLOCKS FIXED
                xlim1=hours(xlim-frs.Time.getDatetime("08:00"));
                
                
            end
        end
        function plotFireRateStatewise(obj)
            ff=FigureFactory.instance('./ExperimentSpecific/PlottingRoutines/UnitPlots/figures');
            params=obj.getParameters;
            smoothfactor=params.fireRatePlotSmoothingFactor;
            sess=obj.getSessionNos;
            try close(3); catch, end; f=figure(3);f.Position=[1,1,2560/2,1348];
            for ises=1:numel(sess)
                sesno=sess(ises);
                sd=obj.getBlockOfChannels(sesno,'SD');
                sd.plotStatewise([],[],1:2:10,smoothfactor)
                AW=sd.getState1(1);
            end
            ff.save('injection')
        end
        function plotFireRateAroundInjection(obj)
            ff=FigureFactory.instance('./ExperimentSpecific/PlottingRoutines/UnitPlots/figures');
            params=obj.getParameters;
            smoothfactor=params.fireRatePlotSmoothingFactor;
            fireratechannels=1:2:10;
%             fireratechannels=11:2:14;
            names={'q1','q2','q3','q4','q5'};
%             names={'mua','int'};
            a=params.interestInMin.before;
            beforeInj1=minutes(a);
            a=params.interestInMin.after;
            afterInj1=minutes(a);
            sess=obj.getSessionNos;
            try close(2); catch, end; f=figure(2);f.Position=[1,1,2560/2,1348];
            for ises=1:numel(sess)
                sesno=sess(ises);
                sd=obj.getBlockOfChannels(sesno,'SD');
                its=obj.getInjectionTimes(sesno)+sd.getDate;
                for iinj=1:numel(its)
                    subplot(numel(sess),2,(ises-1)*2+iinj);
                    it=its(iinj);
                    bi=sd.getWindow(it+beforeInj1);
                    [axplot,axhyp]=bi.plot([],[],fireratechannels,smoothfactor);
                    bi.plotStatewise(axplot,axhyp,fireratechannels,smoothfactor)
                    ai=sd.getWindow(it+afterInj1);
                    [axplot,axhyp,ps]=ai.plot(axplot,axhyp,fireratechannels,smoothfactor);
                    ai.plotStatewise(axplot,axhyp,fireratechannels,smoothfactor)
                    axplot.YScale='log';
                    axplot.XLim=[bi.getStartTime ai.getEndTime];
                    axhyp.XLim=[bi.getStartTime ai.getEndTime];
                    axes(axplot);
                    obj.addInjections(sesno,iinj)
                    if ises==1
                        ylabel('Firing Rate (Hz)');
                        legend(ps,names);
                    end
                end
            end
            ff.save('injection')
        end

    end
    methods (Access=protected)
        function addInjections(obj,sesno,injnum)
            inj1=obj.getInjectionTimes(sesno);
            
            inj=obj.getBlockOfChannels(sesno,'SD').getDate+inj1;
            if exist('injnum','var')
                inj=inj(injnum);
            end
            for iline=1:numel(inj)
                l=xline(inj(iline));
                l.LineStyle='--';
                l.LineWidth=1.5;
                l.Color='r';
            end
        end
        function it=getInjectionTimes(obj,sesno)
            bt=obj.getBlockTimes(sesno);
            sdtime=bt.blockTimes(1,ismember(bt.BlockNames,'SD'));
            it=sdtime+hours(obj.Injections);
        end

        function frs=getFireRates(obj,sessionNo)
            bt=obj.getBlockTimes(sessionNo);
            blocktimes=bt.blockTimes';
            
            timebin=obj.getParameters.timeBinsForFireRateInSeconds;
            sessionNos=obj.getSessionNos;
            sesidx=ismember(sessionNos,sessionNo);
            spikeArraysPerSession=obj.SpikeArrays;
            sa=spikeArraysPerSession(sesidx);
            blocktime_all=[blocktimes(1,1) blocktimes(4,2)];%% all
            frs=sa.getFireRates(timebin);
            block=frs.getWindow(blocktime_all);
            [~,order]=sort(mean(block.Data,2));
            frs=frs.sort(flipud(order));
            ss=buzcode.sleepDetection.StateDetectionData(obj.getLFPFolder(sessionNo)).getStateSeries;
            info.SessionNo=sessionNo;
            info.SortedBasedOn='ALL';
            info.hypnogram=ss;
            frs.Info=info;
        end

    end
end

