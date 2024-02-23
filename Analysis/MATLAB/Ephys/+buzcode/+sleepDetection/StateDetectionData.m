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
        Blocks
        TimeIntervalCombinedDownSampled
        TimeIntervalCombinedOriginal
        BaseName
        Info
    end
    
    methods
        function obj = StateDetectionData(basepath)
            %STATEDETECTIONDATA Construct an instance of this class
            %   Detailed explanation goes here
            logger=logging.Logger.getLogger;
            if ~exist('basepath','var')
                defpath='/data/EphysAnalysis/SleepDeprivationData/';
                defpath1={'*.eeg;*.lfp','Downsampled Files (*.eeg,*.lfp)';...
                    '*.mat','MAT-files (*.mat)'};
                title='Select basepath';
                [~,basepath,~] = uigetfile(defpath1, title, defpath,'MultiSelect', 'on');
            end
            list={'EMGFromLFP','SleepScoreLFP','SleepState',...
                'SleepStateEpisodes'};
            for ilist=1:numel(list)
                thefile=dir(fullfile(basepath,['*',list{ilist},'*']));
                S=load(fullfile(thefile(1).folder,thefile(1).name));
                fname=fieldnames(S);
                obj.(list{ilist})=S.(fname{1});
            end
            key=fullfile(basepath, '*Probe*');
            thefile=dir(key);
            try
                obj.Probe=neuro.probe.Probe(fullfile(thefile(1).folder,thefile(1).name));
                logger.info('Probe is loaded.');
            catch
                logger.error(sprintf('I couldn''t find the Probe file.\n\t%s',key));
            end
            key=fullfile(basepath, '*TimeIntervalCombined*');
            thefile=dir(key);
            try
                ticd=time.TimeIntervalCombined(fullfile(thefile.folder,thefile.name));
                logger.info('Time is loaded.');
            catch
                logger.error(sprintf('I couldn''t find the TimeIntervalCombined file.\n\t%s',key));
            end
            obj.TimeIntervalCombinedOriginal=ticd;
            downsampleFactor=ticd.getSampleRate / obj.SleepScoreLFP.sf;
            timeIntervalCombinedDownsampled=ticd.getDownsampled(downsampleFactor);
            npds=timeIntervalCombinedDownsampled.getNumberOfPoints;
            npss=numel(obj.SleepScoreLFP.t);
            if abs((npds-npss)/npss)<.0001
                
                obj.TimeIntervalCombinedDownSampled=timeIntervalCombinedDownsampled;
            else
                error('Number of samples are not the same in \n\tTimeIntervalCombined(%d) and SleepScoreLFP(%d)',...
                    timeIntervalCombinedDownsampled.getNumberOfPoints,...
                    numel(obj.SleepScoreLFP.t));
            end
            key=fullfile(strcat( basepath, filesep, 'Parameters'), '*Block*');
            thefile=dir(key);
%             try
%                 date1=obj.
%                 loc=fullfile(thefile(1).folder,thefile(1).name);
%                 obj.Blocks=experiment.SDBlocks(date1,loc);
%                 logger.info('Experimental Blocks are loaded.');
%             catch
%                 logger.error(sprintf('I couldn''t find the blocks file.\n\t%s',key));
%             end
            try
                ses=experiment.Session(basepath);
                obj.Blocks=ses.Blocks;
            catch
            end
            list=dir(fullfile(basepath, '*.lfp'));
            [folder,name,~]=fileparts(fullfile(list.folder,list.name));
            obj.BaseName=strcat(folder,filesep,name);
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
            chname=num2str(obj.getThetaChannelID);
            factor=obj.TimeIntervalCombinedOriginal.getSampleRate/obj.SleepScoreLFP.sf;
            ticd=obj.TimeIntervalCombinedOriginal.getDownsampled(factor);
            LFP=neuro.basic.Channel(chname,ch,ticd);
            LFP=LFP.setInfo(obj.Info);
        end
        function [LFP]= getSWLFP(obj)
            ch=double(obj.SleepScoreLFP.swLFP);
            chname=num2str(obj.getSWChannelID);
            factor=obj.TimeIntervalCombinedOriginal.getSampleRate/obj.SleepScoreLFP.sf;
            ticd=obj.TimeIntervalCombinedOriginal.getDownsampled(factor);
            LFP=neuro.basic.Channel(chname,ch,ticd);
            LFP=LFP.setInfo(obj.Info);
        end
        function [ch]= getThetaChannelID(obj)
            ch=obj.SleepScoreLFP.THchanID;
        end
        function [ch]= getSWChannelID(obj)
            ch=obj.SleepScoreLFP.SWchanID;
        end
        function [tps]= getTimePoints(obj,downsample)
            ti=obj.TimeIntervalCombinedOriginal;
            tis=ti.getDownsampled(downsample);
            tps=tis.getTimePoints;
        end
        function [tps]= getTimePointsOriginal(obj)
            ti=obj.TimeIntervalCombinedOriginal;
            tps=ti.getTimePoints;
        end
        function [tps]= getTimePointsDownSampled(obj)
            ti=obj.TimeIntervalCombinedDownSampled;
            tps=ti.getTimePoints;
        end
        function cht=getEMG(obj)
            vals= obj.EMGFromLFP.data;
            chname='EMG';
            factor=obj.TimeIntervalCombinedOriginal.getSampleRate/obj.EMGFromLFP.samplingFrequency;
            ticd=obj.TimeIntervalCombinedOriginal.getDownsampled(factor);
            ticd=ticd.shiftTimePoints(seconds(obj.EMGFromLFP.timestamps(1)));
            ch=neuro.basic.Channel(chname,vals,ticd);
            ch=ch.setInfo(obj.Info);
            cht=neuro.basic.ChannelsThreshold(ch,obj.getEMGThreshold,obj.isEMGSticky);
        end
        function ts=getEMGThreshold(obj)
            ssm=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.EMGthresh;
        end
        function ts=isEMGSticky(obj)
            ssm=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.stickyEMG;
        end
        function cht=getThetaRatio(obj)
            ts1= obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.thratio;
            t=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.t_clus;
            t1=obj.SleepState.idx.timestamps;
            tsr=interp1(t,ts1,t1);
            factor=obj.TimeIntervalCombinedOriginal.getSampleRate/1;
            ticd1=obj.TimeIntervalCombinedOriginal.getDownsampled(factor);
            ticd2=ticd1.shiftTimePoints(seconds( ...
                obj.SleepState.idx.timestamps(1)));
            ticd=ticd2.getTimeIntervalForTimes([ticd2.getStartTime ticd1.getEndTime]);
            ch=neuro.basic.Channel('TH',tsr,ticd);
            ch=ch.setInfo(obj.Info);
            cht=neuro.basic.ChannelsThreshold(ch,obj.getThetaRatioThreshold,obj.isThetaSticky);
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
            warning('Obsolete. Use plot function in Channnel');
            chanSelected=obj.getThetaLFP;
            chanSelected.plot(varargin{:});
            M=nanmean(chanSelected.getVoltageArray);SD=3*nanstd(chanSelected.getVoltageArray);
            ax=gca;
            ax.YLim=[M-SD M+SD];
            ax.XLim=[obj.TimeIntervalCombinedOriginal.getStartTime obj.TimeIntervalCombinedOriginal.getEndTime];
            ax.Color='none';title('');ylabel(chanSelected.getChannelName)
        end
        function []=plotLFP(obj,channel,varargin)
            warning('Obsolete. Use plot function in Channnel');
            chanSelected=obj.getLFP(channel,50);
            chanSelected.plot(varargin{:});
            M=nanmean(chanSelected.getVoltageArray);SD=2*nanstd(chanSelected.getVoltageArray);
            ax=gca;
            ax.YLim=[M-5*SD M+5*SD];
            ax.XLim=[obj.TimeIntervalCombinedOriginal.getStartTime obj.TimeIntervalCombinedOriginal.getEndTime];
            ax.Color='none';title('');ylabel(chanSelected.getChannelName)
        end
        function [LFP]= getLFP(obj,channel,downsamplerate)
            warning('Depricated Method. Use ChannelTimeDataHard.getChannel OR .getCahnnelsLFP.')
            curr=cd(fileparts(obj.BaseName));
            filename=[obj.BaseName '.lfp.ch' num2str(channel) '.' num2str(downsamplerate) '.mat'];
            if ~exist(filename,'file')
                LFP=bz_GetLFP(channel,'downsample',downsamplerate);
                save(filename,'LFP')
            else
                S=load(filename);
                LFP=S.LFP;
            end
            cd(curr)
            ch=double(LFP.data);
            t=obj.getTimePoints(downsamplerate);
            if numel(ch)>=numel(t)
                ch=ch(1:numel(t));
            else
                ch((numel(ch)+1):numel(t))=zeros(numel(t)-numel(ch),1);
                
                warning('Number of points in array adjusted\n\t%d-->%d',numel(ch),numel(t))
            end
            chname=num2str(channel);
            LFP=neuro.basic.Channel(chname,ch,obj.TimeIntervalCombinedOriginal.getDownsampled(downsamplerate));
            LFP=LFP.setInfo(obj.Info);
        end
        function cht=getSW(obj)
            ts1= obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.broadbandSlowWave;
            t=obj.SleepState.detectorinfo.detectionparms.SleepScoreMetrics.t_clus;
            t1=obj.SleepState.idx.timestamps;
            tsr=interp1(t,ts1,t1);
            factor=obj.TimeIntervalCombinedOriginal.getSampleRate/1;
            ticd1=obj.TimeIntervalCombinedOriginal.getDownsampled(factor);
            ticd2=ticd1.shiftTimePoints(seconds( ...
                obj.SleepState.idx.timestamps(1)));
            ticd=ticd2.getTimeIntervalForTimes([ticd2.getStartTime ticd1.getEndTime]);
            ch=neuro.basic.Channel('SW',tsr,ticd);
            ch=ch.setInfo(obj.Info);
            cht=neuro.basic.ChannelsThreshold(ch,obj.getSWThreshold,obj.isSWSticky);
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
            factor=obj.TimeIntervalCombinedOriginal.getSampleRate/1;
            [ticd1,~]=obj.TimeIntervalCombinedOriginal.getDownsampled(factor);
            ticd2=ticd1.shiftTimePoints(seconds(obj.SleepState.idx.timestamps(1)));
            ticd=ticd2.getTimeIntervalForTimes([ticd2.getStartTime ticd1.getEndTime]);
            try
                ss=neuro.state.StateSeries(states,ticd);
            catch ME
                if numel(states)-ticd.getNumberOfPoints==1
                        ticd=ticd.addTimePoints(1);
                        ss=neuro.state.StateSeries(states,ticd);
                elseif numel(states)-ticd.getNumberOfPoints==-1
                    ticd=ticd.addTimePoints(-1);
                    ss=neuro.state.StateSeries(states,ticd);
                else
                    error(ME.message);
                end
            end
            ss=ss.setEpisodesFromBuzcode(obj.SleepState.ints);
            ss=ss.setStateNames(categorical(idx.statenames));
        end
        function ch=getStateSeriesChannel(obj)
            idx=obj.SleepState.idx;
            states=idx.states;
            factor=obj.TimeIntervalCombinedOriginal.getSampleRate/1;
            ticd1=obj.TimeIntervalCombinedOriginal.getDownsampled(factor);
            ticd2=ticd1.shiftTimePoints(seconds( ...
                obj.SleepState.idx.timestamps(1)));
            ticd=ticd2.getTimeIntervalForTimes([ticd2.getStartTime ticd1.getEndTime]);
            ch=neuro.basic.Channel('StS',states,ticd);
            ch=ch.setInfo(obj.Info);
            ch.Info.statenames=idx.statenames;
        end
        function probe=getProbe(obj)
            probe=obj.Probe;
        end
        function [powerSpectrums, filename]=plot(obj,channel,varargin)
            if nargin>2
                window1=varargin{1};
                saveplot=varargin{2};
                st=obj.TimeIntervalCombinedDownSampled.getStartTime;
                window=window1+datetime(st.Year, st.Month, st.Day);
            else
                window=[obj.TimeIntervalCombinedDownSampled.getStartTime obj.TimeIntervalCombinedDownSampled.getEndTime];
            end
            ticd=obj.TimeIntervalCombinedOriginal.getTimeIntervalForTimes(window);
            t(1)=obj.TimeIntervalCombinedOriginal.getSampleFor(window(1));
            t(2)=obj.TimeIntervalCombinedOriginal.getSampleFor(window(2));
            
            colorl=linspecer(5);
            statesmap=containers.Map([1 2 3 5],{'A-WAKE','Q-WAKE','SWS','REM'});
            colors=containers.Map([0 1 2 3 5],{colorl(1,:),colorl(2,:),colorl(3,:),colorl(4,:),colorl(5,:)});
            figure('units','normalized','outerposition',[0 1/5 1 3/5]);
            
            size.left.heigth.thin=.1;
            size.left.heigth.thick=.2;
            size.left.width.thin=.1;
            size.left.width.thick=.1;
            size.right.heigth.thin=.1;
            size.right.heigth.thick=.2;
            size.right.width.thin=.1;
            size.right.width.thick=.1;
            
            tf=axes;
            tf.Position(1)=0.05;
            tf.Position(3)=.7-tf.Position(1);
            tf.Position(2)=0.2;tf.Position(4)=0.175;
            raw=axes;
            raw.Position=tf.Position;
            raw.Position(2)=.1;
            raw.Position(4)=.075;
            obj.plotLFP(channel)
            %             obj.plotThetaLFP('Color','k');
            hold on
            blcks=obj.Blocks.getTimeTable;clr=[.3 .3 .3];
            for ibl=1:height(blcks)
                plot([blcks.t1(ibl) blcks.t2(ibl)],[0 0],...
                    'LineWidth',4,'Color',clr);
                plot([blcks.t1(ibl) blcks.t1(ibl)],[raw.YLim(1)/2 raw.YLim(2)/2],...
                    'LineWidth',3,'Color',clr);
                plot([blcks.t2(ibl) blcks.t2(ibl)],[raw.YLim(1)/2 raw.YLim(2)/2],...
                    'LineWidth',3,'Color',clr);
                text(blcks.t1(ibl)+(blcks.t2(ibl)-blcks.t1(ibl))/2,...
                    0,blcks.Block{ibl},'Color',clr*2,'FontSize',20,'HorizontalAlignment','center')
            end
            plot([ticd.getStartTime ticd.getStartTime ticd.getEndTime ticd.getEndTime ticd.getStartTime],...
                [raw.YLim(1) raw.YLim(2) raw.YLim(2) raw.YLim(1) raw.YLim(1)],'LineWidth',2,'Color','r');
            
            states=axes;
            states.Position=raw.Position;
            states.Position(2)=tf.Position(2)+tf.Position(4)+.02;
            states.Position(4)=.05;
            states.XTick=[];
            ch=obj.getStateSeries;
            ch.plot();
            
            hold on
            ticdds=obj.TimeIntervalCombinedDownSampled;
            tps=ticdds.getTimePointsInAbsoluteTimes;
            plot([tps(ticdds.getSampleFor(window(1))) tps(ticdds.getSampleFor(window(1))) tps(ticdds.getSampleFor(window(2))) tps(ticdds.getSampleFor(window(2))) tps(ticdds.getSampleFor(window(1)))],...
                [states.YLim(1) states.YLim(2) states.YLim(2) states.YLim(1) states.YLim(1)],'LineWidth',2,'Color','k');
            
            theta=axes;
            theta.Position=raw.Position;
            theta.Position(2)=states.Position(2)+states.Position(4)+.02;
            theta.XTick=[];
            ch=obj.getThetaRatio();
            ch.plot();hold on;
            theta.YLim=[0 1];
            theta.XLim=[ch.getTimeIntervalCombined.getStartTime ch.getTimeIntervalCombined.getEndTime];
            theta.XTickLabel='';
            plot(theta.XLim,[obj.getThetaRatioThreshold obj.getThetaRatioThreshold],'Color','r')
            theta.Color='none';title('');
            theta.Box='off';
            theta.YLabel.String=ch.getChannelName;
            tx=text(.02,.5,'\theta-ratio','Units','normalized');tx.FontSize=20;
            if obj.isThetaSticky
                tx=text(.98,double(obj.getThetaRatioThreshold),'Sticky','Units','normalized');tx.FontSize=10;
                tx.Color='r';tx.HorizontalAlignment='right';
            end
            
            EMG=axes;
            EMG.Position=raw.Position;
            EMG.Position(2)=theta.Position(2)+theta.Position(4);
            EMG.XTick=[];
            ch=obj.getEMG();
            ch.plot();hold on;
            EMG.YLim=[0 1];
            EMG.XLim=[ch.getTimeIntervalCombined.getStartTime ch.getTimeIntervalCombined.getEndTime];
            EMG.XTickLabel='';
            plot(EMG.XLim,[obj.getEMGThreshold obj.getEMGThreshold],'Color','r')
            EMG.Color='none';title('');
            EMG.Box='off';EMG.YLabel=[]
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
            
            broad=axes;
            broad.Position=raw.Position;
            broad.Position(2)=EMG.Position(2)+EMG.Position(4);
            broad.XTick=[];
            ch=obj.getSW();
            ch.plot();hold on;
            broad.YLim=[0 1];
            broad.XLim=[ch.getTimeIntervalCombined.getStartTime ch.getTimeIntervalCombined.getEndTime];
            plot(broad.XLim,[obj.getSWThreshold obj.getSWThreshold],'Color','r')
            broad.Color='none';title('');
            broad.Box='off';broad.YLabel=[];
            tx=text(.02,.5,'Broad-Band SW','Units','normalized');tx.FontSize=20;
            if obj.isSWSticky
                tx=text(.98,double(obj.getSWThreshold),'Sticky','Units','normalized');tx.FontSize=10;
                tx.Color='r';tx.HorizontalAlignment='right';
            end
            
            lfp=obj.getLFP(channel,1);
            
            keys=statesmap.keys;
            keysPlotted=[];proportion=nan(1,5);
            ivalid=1;
            ss=obj.getStateSeries;
            ss1=ss.getResampled(lfp);
            for istate=1:statesmap.Count
                key=keys{istate};
                idxkey=ss1.States==key;
                mask=false(numel(idxkey),1);
                mask(t(1):t(2))=true;
                idx=idxkey & mask;
                proportion(key)=sum(idx)/sum(mask);
                aChan1=lfp.getTimePoints(idx);
                try
                    powerSpectrumState{ivalid}=aChan1.getPSpectrum();
                    powerSpectrumSlope{ivalid}=aChan1.getPSpectrumSlope();
                    TFState{ivalid}=aChan1.getTimeFrequencyMap(TimeFrequencyChronuxMtspecgramc(1:1:250,[2 1]));
                    keysPlotted=horzcat(keysPlotted, key);ivalid=ivalid+1;
                catch
                    fprintf('Some Problem at loading PowerSpectrums or TimeFrequencies')
                end
            end
            clear ts
            all=lfp.getTimePoints(mask);
            powerSpectrumAll=all.getPSpectrum();
            powerSpectrumslopeAll=all.getPSpectrumSlope();
            tfmapall=all.getTimeFrequencyMap(TimeFrequencyChronuxMtspecgramc(1:1:250,[2 1]));
            pwrspctrm=axes;
            p0=powerSpectrumAll.semilogx([0 250],[15 60]);
            hold on
            p0.LineWidth=1.5;
            p0.Color=colors(0);
            lbls=[];lbls{1}='ALL';
            powerSpectrums=PowerSpectrumCombined;
            powerSpectrumAll=powerSpectrumAll.setInfoNumAndName(0,'ALL');
            powerSpectrumAll=powerSpectrumAll.addTimeFrequencyEnhance(tfmapall);
            powerSpectrumAll=powerSpectrumAll.addPowerSpectrumSlope(powerSpectrumslopeAll);
            powerSpectrums=powerSpectrums+powerSpectrumAll;
            for istate=1:numel(keysPlotted)
                try
                    key=keysPlotted(istate);
                    pss=powerSpectrumState{istate};
                    p1(istate)=pss.semilogx([0 250],[10 60]);
                    p1(istate).Color=colors(key);
                    p1(istate).LineWidth=3*proportion(key)+.5;
                    lbls=horzcat(lbls,{statesmap(keysPlotted(istate))});
                    pss=pss.setInfoNumAndName(keysPlotted(istate),statesmap(keysPlotted(istate)));
                    pss=pss.setSignalLength(proportion(key));
                    pss=pss.addTimeFrequencyEnhance(TFState{istate});
                    pss=pss.addPowerSpectrumSlope(powerSpectrumSlope{istate});
                    powerSpectrums=powerSpectrums+pss;
                catch
                end
            end
            legend([p0 p1],lbls)
            pwrspctrm.Position=raw.Position;
            pwrspctrm.Position(1)=raw.Position(1)+raw.Position(3)+.03;
            pwrspctrm.Position(3)=1-pwrspctrm.Position(1)-.05;
            pwrspctrm.Position(4)=1-pwrspctrm.Position(2)-.5;
            
            stateprop=axes;
            stateprop.Position=pwrspctrm.Position;
            stateprop.Position(1)=pwrspctrm.Position(1)+pwrspctrm.Position(3)+.01;
            stateprop.Position(3)=.01;
            b1=bar(1,proportion*100,'stacked');
            stateprop.YLim=[0 100];
            stateprop.XLim=[0.9 1.1];
            for istate=1:statesmap.Count
                key=keys{istate};
                b1(key).FaceColor=colors(key);
                b1(key).EdgeColor=colors(key);
            end
            stateprop.XTick=[];
            stateprop.Box='off';
            stateprop.Color='none';
            
            probe=axes;
            probe.Position=pwrspctrm.Position;
            probe.Position(2)=pwrspctrm.Position(2)+pwrspctrm.Position(4)+.01;
            probe.Position(4)=.20;
            obj.Probe.plotProbeLayout(lfp.getChannelNumber+1)
            probe.Visible='off';
            
            folder=obj.BaseName;
            formatOut = 'HH-MM-SS';
            
            filesave=sprintf('%s%s_%s-%s',folder,...
                lfp.getChannelName,...
                datestr(window(1), formatOut),...
                datestr(window(2), formatOut)...
                );
            
            
            if saveplot
                lfp=obj.getLFP(channel,1);
                chanw=lfp.getWhitened();
                tfmsel=chanw.getTimeFrequencyMap(...
                    TimeFrequencyChronuxMtspecgramc(1:.1:30,[2 1])...
                    );
                clear chanw
                axes(tf);
                tfmsel.plot()
                tf.YDir='normal';
                tf.XTick=[];
                tx=text(.02,.5,[lfp.getChannelName ''],'Units','normalized');tx.FontSize=20;
                
                
                folder=obj.BaseName;
                formatOut = 'HH-MM-SS';
                FigureFactory.instance.save([filesave '.png']);
            end
            formatOut = 'HH-MM-SS';
            filename=sprintf('%s_%s-%s',...
                lfp.getChannelName,...
                datestr(window(1), formatOut),...
                datestr(window(2), formatOut)...
                );
            save([filesave '.powerspec.mat'],'powerSpectrums')
        end
        
    end
    methods (Access=private)
        
        function ts=getTimeSeriesForArraywBAD(obj,array)
            %             tp=obj.TimeIntervalCombinedDownSampled.getTimePoints;
            %
            %             ts=timeseries(array,tp);
            %             ts.TimeInfo.StartDate=obj.TimeIntervalCombined.getStartTime;
        end
        function range=getRange(obj,timeWindow)
            ss=obj.StatesSeries;
            twsec=seconds(timeWindow-ss.TimeInfo.StartDate);
            
            range=(ss.Time>twsec(1))&(ss.Time<=twsec(2));
        end
        function basepath=getBasePath(~, basename)
            basepath=fileparts(basename);
        end
    end
end