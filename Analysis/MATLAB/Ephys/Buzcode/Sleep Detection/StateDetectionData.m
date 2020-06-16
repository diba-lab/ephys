classdef StateDetectionData
    %STATEDETECTIONDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    properties (Access=public)
        EMGFromLFP
        SleepScoreLFP
        SleepState
        SleepStateEpisodes
        Probe
        TimeIntervalCombined
        BaseName
    end
    
    methods
        function obj = StateDetectionData(basename)
            %STATEDETECTIONDATA Construct an instance of this class
            %   Detailed explanation goes here
            list={'EMGFromLFP','SleepScoreLFP','SleepState',...
                'SleepStateEpisodes'};
            basepath=obj.getBasePath(basename);
            for ilist=1:numel(list)
                thefile=dir([basename, '*',list{ilist},'*']);
                S=load(fullfile(thefile(1).folder,thefile(1).name));
                fname=fieldnames(S);
                obj.(list{ilist})=S.(fname{1});
            end
            thefile=dir(fullfile(basepath, '*Probe*'));
            try
                obj.Probe=Probe(fullfile(thefile(1).folder,thefile(1).name));
            catch
                warning('I couldn''t find the Probe file.\n\t%s',thefile);
            end
            thefile=dir(fullfile(basepath, '*TimeIntervalCombined*'));
            try
                S=load(fullfile(thefile(1).folder,thefile(1).name));
            catch
                warning('I couldn''t find the TimeIntervalCombined file.\n\t%s',thefile);
            end
            fname=fieldnames(S);
            timeIntervalCombined=S.(fname{1});
            downsampleFactor=timeIntervalCombined.getSampleRate/obj.SleepScoreLFP.sf;
            timeIntervalCombinedDownsampled=timeIntervalCombined.getDownsampled(downsampleFactor);
            npds=timeIntervalCombinedDownsampled.getNumberOfPoints;
            npss=numel(obj.SleepScoreLFP.t);
            if abs((npds-npss)/npss)<.0001
                
                obj.TimeIntervalCombined=timeIntervalCombinedDownsampled;
            else
                error('Number of samples are not the same in \n\tTimeIntervalCombined(%d) and SleepScoreLFP(%d)',...
                    timeIntervalCombinedDownsampled.getNumberOfPoints,...
                    numel(obj.SleepScoreLFP.t));
            end
            obj.BaseName=basename;
        end
        
        function episodes= joinStates(obj)
            %% JOIN STATES INTO EPISODES
            
            % Extract states, Episodes, properly organize params etc, prep for final saving
            display('Calculating/Saving Episodes')
            episodes=StatesToEpisodes(obj.SleepStateStruct,obj.BasePath);
        end
        function []= openStateEditor(obj)
            TheStateEditor(obj.BaseName);
        end
        function [LFP]= getThetaLFP(obj)
            ch=double(obj.SleepScoreLFP.thLFP);
            t=obj.getTimePoints;
            if numel(ch)>=numel(t)
                ch=ch(1:numel(t));
            else
                t=t(1:numel(ch));
                
                warning('Number of points in array adjusted\n\t%d-->%d',numel(ch),numel(t))
            end
            chname=num2str(obj.getThetaChannelID);
            starttime=obj.TimeIntervalCombined.getStartTime;
            LFP=Channel(chname,ch,t,starttime);
        end
        function [LFP]= getThetaChannelID(obj)
            LFP=obj.SleepScoreLFP.THchanID;
        end
        function [tps]= getTimePoints(obj)
            ti=obj.TimeIntervalCombined;
            tps=ti.getTimePointsInSec;
        end
        function ts=getEMG(obj)
            ts1= obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.EMG;
            ts=obj.getTimeSeriesForArray(ts1);
        end
        function ts=getEMGThreshold(obj)
            ssm=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.EMGthresh;
        end
        function ts=isEMGSticky(obj)
            ssm=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.stickyEMG;
        end
        function ts=getThetaRatio(obj)
            ts1= obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.thratio;
            ts=obj.getTimeSeriesForArray(ts1);
        end
        function ts=getThetaRatioThreshold(obj)
            ssm=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.THthresh;
        end
        function ts=isThetaSticky(obj)
            ssm=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.stickyTH;
        end
        function ts=plotThetaLFP(obj,varargin)
            chanSelected=obj.getThetaLFP;
            p1(1)=chanSelected.getTimeSeries.plot(varargin{:});
            M=nanmean(chanSelected.getVoltageArray);SD=8*nanstd(chanSelected.getVoltageArray);
            ax=gca;
            ax.YLim=[M-SD M+SD];
            ts=chanSelected.getTimeSeries;
            ax.XLim=seconds([ts.Time(1) ts.Time(end)])+ts.TimeInfo.StartDate;
            ax.Color='none';title('');ylabel(chanSelected.getChannelName)
        end
        
        function ts=getSW(obj)
            ts1= obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.broadbandSlowWave;
            ts=obj.getTimeSeriesForArray(ts1);
        end
        function ts=getSWThreshold(obj)
            ssm=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.swthresh;
        end
        function ts=isSWSticky(obj)
            ssm=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.stickySW;
        end
        function ss=getStateSeries(obj)
            idx=obj.SleepState.idx;
            states=idx.states;
            ts=obj.getTimeSeriesForArray(states);
            ss=StateSeries(ts);
        end
        function ss=plot(obj,varargin)
            if nargin>1
                window1=varargin{1};
                st=obj.TimeIntervalCombined.getStartTime;
                window=window1+datetime(st.Year, st.Month, st.Day);
            else
                window=[obj.TimeIntervalCombined.getStartTime obj.TimeIntervalCombined.getEndTime];
            end
            ticd=obj.TimeIntervalCombined.getTimeIntervalForTimes(window(1),window(2));
            t(1)=obj.TimeIntervalCombined.getSampleFor(window(1));
            t(2)=obj.TimeIntervalCombined.getSampleFor(window(2));
            
            colorl=linspecer(5);
            states=containers.Map([1 2 3 5],{'A-WAKE','Q-WAKE','SWS','REM'});
            colors=containers.Map([0 1 2 3 5],{colorl(1,:),colorl(2,:),colorl(3,:),colorl(4,:),colorl(5,:)});
            figure('units','normalized','outerposition',[0 1/5 1 3/5]);
            
            size.heigth.thin=.1;
            size.heigth.thick=.2;
            size.width.thin=.1;
            size.width.thick=.1;
            
            ax=axes;
            ax.Position(1)=0.05;
            ax.Position(3)=.7-ax.Position(1);
            ax.Position(2)=0.15;ax.Position(4)=0.175;
            ax2=axes;
            ax2.Position=ax.Position;
            ax2.Position(2)=.05;
            ax2.Position(4)=.075;
            obj.plotThetaLFP('Color','k');
            
            hold on
            plot([ticd.getStartTime ticd.getStartTime],ax2.YLim,'LineWidth',2,'Color','r');
            plot([ticd.getEndTime ticd.getEndTime],ax2.YLim,'LineWidth',2,'Color','r');
            
            ax3=axes;
            ax3.Position=ax2.Position;
            ax3.Position(2)=ax.Position(2)+ax.Position(4);
            ax3.XTick=[];
            ss=obj.getStateSeries;
            ss.plot(colors);
            
            hold on
            ticdds=obj.TimeIntervalCombined.getDownsampled(ticd.getSampleRate)
            tps=ticdds.getTimePointsInSec;
            plot([tps(ticdds.getSampleFor(window(1))) tps(ticdds.getSampleFor(window(1)))],ax3.YLim,'LineWidth',2,'Color','k');
            plot([tps(ticdds.getSampleFor(window(2))) tps(ticdds.getSampleFor(window(2)))],ax3.YLim,'LineWidth',2,'Color','k');
            
            ax4=axes;
            ax4.Position=ax2.Position;
            ax4.Position(2)=ax3.Position(2)+ax3.Position(4);
            ax4.XTick=[];
            ss=obj.getThetaRatio();
            ss.plot();hold on;
            ax4.YLim=[0 1];
            ax4.XLim=seconds([ss.Time(1) ss.Time(end)])+ss.TimeInfo.StartDate;
            ax4.XTickLabel='';
            plot(ax4.XLim,[obj.getThetaRatioThreshold obj.getThetaRatioThreshold],'Color','r')
            ax4.Color='none';title('');
            ax4.Box='off';
            tx=text(.02,.5,'\theta-ratio','Units','normalized');tx.FontSize=20;
            if obj.isThetaSticky
                tx=text(.98,double(obj.getThetaRatioThreshold),'Sticky','Units','normalized');tx.FontSize=10;
                tx.Color='r';tx.HorizontalAlignment='right';
            end
            
            ax5=axes;
            ax5.Position=ax2.Position;
            ax5.Position(2)=ax4.Position(2)+ax4.Position(4);
            ax5.XTick=[];
            ss=obj.getEMG();
            ss.plot();hold on;
            ax5.YLim=[0 1];
            ax5.XLim=seconds([ss.Time(1) ss.Time(end)])+ss.TimeInfo.StartDate;
            ax5.XTickLabel='';
            plot(ax5.XLim,[obj.getEMGThreshold obj.getEMGThreshold],'Color','r')
            ax5.Color='none';title('');
            ax5.Box='off';
            tx=text(.02,.5,'EMG','Units','normalized');tx.FontSize=20;
            if obj.isEMGSticky
                tx=text(.98,double(obj.getEMGThreshold),'Sticky','Units','normalized');tx.FontSize=10;
                tx.Color='r';tx.HorizontalAlignment='right';
            end
            
            % evts=theOer.getEvents;
            % for ievent=1:numel(evts)
            %     evt=evts(ievent);
            %     p1=plot([datetime(evt.StartDate)+seconds(evt.Time)...
            %         datetime(evt.StartDate)+seconds(evt.Time)],...
            %         [0 1]);
            %     p1.LineWidth=2;
            %     try
            %         p1.Color=colore(evt.Name);
            %     catch
            %         p1.Color='k';
            %     end
            % end
            
            ax6=axes;
            ax6.Position=ax2.Position;
            ax6.Position(2)=ax5.Position(2)+ax5.Position(4);
            ax6.XTick=[];
            ss=obj.getSW();
            ss.plot();hold on;
            ax6.YLim=[0 1];
            ax6.XLim=seconds([ss.Time(1) ss.Time(end)])+ss.TimeInfo.StartDate;
            plot(ax6.XLim,[obj.getSWThreshold obj.getSWThreshold],'Color','r')
            ax6.Color='none';title('');
            ax6.Box='off';
            tx=text(.02,.5,'Broad-Band SW','Units','normalized');tx.FontSize=20;
            if obj.isSWSticky
                tx=text(.98,double(obj.getSWThreshold),'Sticky','Units','normalized');tx.FontSize=10;
                tx.Color='r';tx.HorizontalAlignment='right';
            end
            
            thetaChan=obj.getThetaLFP;
            
            keys=states.keys;
            keysPlotted=[];
            ivalid=1;
            ss=obj.getStateSeries;
            ts1=ss.ts;
            ts=ts1.resample(thetaChan.getTimeSeries.time,'zoh');
            for istate=1:states.Count
                key=keys{istate};
                idxkey=ts.Data==key;
                mask=false(numel(idxkey),1);
                mask(t(1):t(2))=true;
                idx=idxkey & mask;
                aChan1=thetaChan.getTimePoints(idx);
                try
                    powerSpectrumState{ivalid}=aChan1.getPSpectrum();ivalid=ivalid+1;
                    keysPlotted=horzcat(keysPlotted, key);
                catch
                end
            end
            
            powerSpectrum=thetaChan.getPSpectrum();
            ax7=axes;
            p0=powerSpectrum.plot([0 30]);
            hold on
            p0.LineWidth=1.5;
            p0.Color=colors(0);
            inum=2;lbls=[];lbls{1}='All';
            for istate=1:numel(keysPlotted)
                try
                    pss=powerSpectrumState{istate};
                    p1(istate)=pss.plot([0 100]);
                    p1(istate).Color=colors(keysPlotted(istate));inum=inum+1;
                    p1(istate).LineWidth=1.5;
                    lbls=horzcat(lbls,{states(keysPlotted(istate))});
                catch
                end
            end
            legend([p0 p1],lbls)
            ax7.Position=ax.Position;
            ax7.Position(1)=ax.Position(1)+ax.Position(3)+.03;
            ax7.Position(3)=1-ax7.Position(1)-.03;
            ax7.Position(4)=1-ax7.Position(2)-.4;
            
            
            
            load('masmanides_128Kx2.mat');
            axs3=axes;
            axs3.Position=ax7.Position;
            axs3.Position(2)=ax7.Position(2)+ax7.Position(4)+.03;
            axs3.Position(3)=ax7.Position(3);
            masmanidis_128Kx2.plotProbeLayout(thetaChan.getChannelNumber)
            axs3.Visible='off';
            
            thetaChan=obj.getThetaLFP;
            thetaChanw=thetaChan.getWhitened();
            tfmsel=thetaChanw.getTimeFrequencyMap(...
                TimeFrequencyChronuxMtspecgramc(1:.1:30,[2 1])...
                );
            axes(ax);
            tfmsel.plot()
            ax.YDir='normal';
            ax.Position(1)=0.05;
            ax.Position(3)=.7-ax.Position(1);
            ax.Position(2)=0.15;ax.Position(4)=0.175;
            ax.XTick=[];
            tx=text(.02,.5,[thetaChan.getChannelName ''],'Units','normalized');tx.FontSize=20;
            
            
            folder=obj.BaseName;
            formatOut = 'HH-MM-SS';
            FigureFactory.instance.save(...
                sprintf('%s%s_%s-%s.png',folder,...
                thetaChan.getChannelName,...
                datestr(window(1), formatOut),...
                datestr(window(2), formatOut)...
                )...
                );
        end
        
    end
    methods (Access=private)
        function ts=getTimeSeriesForArray(obj,array)
            tp=obj.TimeIntervalCombined.getDownsampled(obj.TimeIntervalCombined.getSampleRate*1).getTimePointsInSec;
            if numel(tp)>=numel(array)
                tp=tp(1:numel(array));
            end
            ts=timeseries(array,tp);
            ts.TimeInfo.StartDate=obj.TimeIntervalCombined.getStartTime;
        end
        function ts=getTimeSeriesForArraywBAD(obj,array)
            tp=obj.TimeIntervalCombined.getDownsampled(obj.TimeIntervalCombined.getSampleRate*1).getTimePointsInSec;
            
            ts=timeseries(array,tp);
            ts.TimeInfo.StartDate=obj.TimeIntervalCombined.getStartTime;
        end
        function range=getRange(obj,timeWindow)
            ss=obj.StatesSeries;
            twsec=seconds(timeWindow-ss.TimeInfo.StartDate);
            ransudo -i
            range=(ss.Time>twsec(1))&(ss.Time<=twsec(2));
        end
        function basepath=getBasePath(~, basename)
            tokens=tokenize(basename,filesep);
            basepath=[filesep fullfile(tokens{1:numel(tokens)-1})];
        end
    end
end