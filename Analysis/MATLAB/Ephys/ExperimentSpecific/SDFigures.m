classdef SDFigures <Singleton
    %FIGURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FileTable
        Colors
        Sa
        Sdd
        bc
        track
    end
    
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function obj = SDFigures()
            % Initialise your custom properties.
            obj.FileTable=readtable(...
                fullfile('/data/EphysAnalysis/Structure', 'LFPfiles.txt'),...
                'Delimiter',',');
            trackFiles=readtable(...
                fullfile('/data/EphysAnalysis/Structure', 'TrackFiles.txt'),...
                'Delimiter',',');
            colors=linspecer(4,'qualitative');
            obj.Colors=containers.Map([1 2 3 5],...
                {colors(2,:),colors(1,:),colors(3,:),colors(4,:)});
            
            sf=SpikeFactory.instance;
            t_all=readtable('clusters.txt','Delimiter',',');
            animal='AG';
            day=1;
            shanks=1:6;
            locations={'CA1','CA3'};
            idx_animal=ismember(t_all.animal,animal);
            idx_day=ismember(t_all.day,day);
            idx_shank=ismember(t_all.shank,shanks);
            idx_location=ismember(t_all.location,locations);
            idx_all=idx_animal&idx_day&idx_shank;
            folders=t_all.path(idx_all,:);
            clear sa sa_adj
            for ishank=shanks
                folder=folders{ishank};
                [sa1, folder]=sf.getSpykingCircusOutputFolder(folder);
                sa1=sa1.setShank(ishank);
                sa1=sa1.setLocation(t_all.location(ishank));
                try
                    %         sa_adj=sa_adj+sa1.getSpikeArrayWithAdjustedTimestamps;
                    sa=sa+sa1;
                catch
                    %         sa_adj=sa1.getSpikeArrayWithAdjustedTimestamps;
                    sa=sa1;
                end
            end
            obj.Sa=sa;
            
            t_lfp=readtable('LFPfiles.txt','Delimiter',',');
            idx_animal=ismember(t_lfp.animal,animal);
            idx_day=ismember(t_lfp.day,day);
            idx_all=idx_animal&idx_day;
            filepath=t_lfp.Filepath{idx_all};
            obj.Sdd=StateDetectionData(filepath);
            
            obj.bc=BuzcodeFactory.getBuzcode(filepath);
            
            ol=OptiLoader.instance(trackFiles.Filepath);
            obj.track=ol.getOptiFilesCombined.getChannels;
        end
    end
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = SDFigures();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        
        
        function outputArg = runBasics(obj,fileNos,timeNos, channel)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            files = obj.FileTable;
            if ~exist('fileNos','var')||isempty(fileNos)
                fileNos=1:numel(files.Condition);
            end
            freqinterest=[1 250];
            movingwindow=[2 1];
            freqinterests={[0 4],[4 12],[50 100],[120 250]};
            freqinterests_enlarge=[1 1 3 3];
            freqinterests_plotat=[20 40 90 175];
            blockscfg.plotat=125;
            blockscfg.linewidth=2;
            blockscfg.color=[.7 .7 .7];
            powerrange=[0 50];
            medianfilter=3;
            for ifile=fileNos
                file=files.Filepath{ifile};
                ctd=ChannelTimeData(file);
                ch=ctd.getChannel(channel);
                str=[file num2str(ch.getChannelName) 'tfmap1'];
                cachefile=fullfile(file,'cache', [DataHash(str) '.mat']);
                if ~exist(cachefile,'file')
                    tfmap=ch.getTimeFrequencyMap(TimeFrequencyChronuxMtspecgramc(...
                        freqinterest,movingwindow));
                    tfmap1=tfmap.getTimePointsAdjusted;
                    if ~exist(fullfile(file,'cache'),'dir')
                        mkdir(fullfile(file,'cache'));
                    end
                    save(cachefile,'tfmap1');
                else
                    load(cachefile,'tfmap1');
                end
                try close(ifile);catch, end; figure(ifile);
                tfmap1.plot(gca,powerrange);
                hold on;
                states = [1 2 3 5];
                ss=StateDetectionData(file).getStateSeries;
                for ifreq=1:numel(freqinterests)
                    plotat=freqinterests_plotat(ifreq);
                    freqint=freqinterests{ifreq};
                    str=[file num2str(ch.getChannelName) 'tfmap'];
                    cachefile=fullfile(file,'cache', [DataHash(str) '.mat']);
                    if ~exist(cachefile,'file')
                        tfmap=ch.getTimeFrequencyMap(TimeFrequencyChronuxMtspecgramc(...
                            freqinterest,movingwindow));
                        if ~exist(fullfile(file,'cache'),'dir')
                            mkdir(fullfile(file,'cache'));
                        end
                        save(cachefile,'tfmap');
                    else
                        load(cachefile,'tfmap');
                    end
                    meanFreq=tfmap.getMeanFrequency(freqint);
                    meanFreq(meanFreq<0)=nan;
                    meanFreq(zscore(meanFreq)>3)=nan;
                    meanPower=round(nanmean(meanFreq));
                    meanFreq=(meanFreq-meanPower)*freqinterests_enlarge(ifreq)+plotat;
                    t=hours(seconds(tfmap.timePoints));
                    for istate=states
                        meanFreq1=medfilt1(meanFreq,medianfilter);
                        ind_state=ss.getIndexForState(istate);
                        meanFreq1(~ind_state(1:numel(meanFreq1)))=nan;
                        p1(istate)=plot(t,meanFreq1);
                        p1(istate).LineWidth=2;
                        p1(istate).Color=obj.Colors(istate);
                    end
                    plot([t(1) t(end)],[plotat plotat],'Color','k')
                    t1=text(t(1), plotat, sprintf('%d-%d ', freqint),...
                        'HorizontalAlignment','right');
                    t1.FontSize=8;
                    t1=text(t(end), plotat+10, [num2str(meanPower) 'dB '],...
                        'HorizontalAlignment','right');
                    t1.BackgroundColor='w';
                    
                end
                try
                    filename=dir(fullfile(file,'*BlockTimes*.*'));
                    S=load(fullfile(file,filename.name));
                    fnames=fieldnames(S);
                    blocks=S.(fnames{1});
                    TT=blocks.TimeTable;
                    for iblock=1:height(TT)
                        st=TT.start(iblock);
                        en=TT.end1(iblock);
                        t=ss.TimeIntervalCombined.getTimePointsInSec;
                        sts=hours(seconds(t(ss.TimeIntervalCombined.getSampleFor(st))));
                        ens=hours(seconds(t(ss.TimeIntervalCombined.getSampleFor(en))));
                        name=TT.name(iblock);
                        if iblock==2
                            title(name);
                        end
                        plot([sts ens],[blockscfg.plotat blockscfg.plotat],'LineWidth',...
                            blockscfg.linewidth,'Color',blockscfg.color);
                        plot([sts sts],[blockscfg.plotat-3 blockscfg.plotat+3],...
                            'LineWidth',1,'Color',blockscfg.color);
                        plot([ens ens],[blockscfg.plotat-3 blockscfg.plotat+3],...
                            'LineWidth',1,'Color',blockscfg.color);
                        text(mean([sts ens]),blockscfg.plotat,name,...
                            'HorizontalAlignment','center','VerticalAlignment','bottom',...
                            'FontWeight','bold','Color', blockscfg.color);
                    end
                catch
                end
                mainax=gca;
                bc=BuzcodeFactory.getBuzcode(file);
                ripple=bc.calculateSWR;
                ticd=ripple.TimeIntervalCombined;
                peaktimestamps=ripple.PeakTimes*ticd.getSampleRate;
                peakTimeStampsAdjusted=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestamps);
                peakTimesAdjusted=peakTimeStampsAdjusted/ticd.getSampleRate;
                peakripmax=ripple.RipMax(:,1);
                s=scatter(hours(seconds(peakTimesAdjusted)),200+peakripmax...
                    ,'Marker','.','MarkerFaceAlpha',.7,'MarkerEdgeAlpha',.7,...
                    'SizeData',50);
                t=ss.TimeIntervalCombined.getTimePointsInSec;
                [N,edges]=histcounts(peakTimesAdjusted,1:30:t(end));
                t=hours(seconds(edges(1:(numel(edges)-1))+15));
                t1=linspace(min(t),max(t),numel(t)*10);
                N=interp1(t,N,t1,'spline','extrap');
                p2=plot(t1,N+200,'LineWidth',1);
                legend([p1(1) p1(2) p1(3) p1(5) p2 s],...
                    {'A-WAKE'; 'Q-WAKE' ; 'SWS'; 'REM'; 'SWR Rate'; 'SWR Event'},...
                    "Location",'northwest','Box','off')
                ax=axes;
                ax.Position=[.0 .0 .2 .1];
                ax.Visible='off';
                probe=ctd.getProbe;
                probe.setActiveChannels(channel).plotProbeLayout(channel)
                
                %                 ss1=ss.getResampled(ch);
                %                 table=readtimetable(fullfile(file,'TimeOfInterests_timetable.txt'));
                %                 if ~exist('timeNos','var')||~isempty('timeNos')
                %                     timeNos=1:numel(table.t1);
                %                 end
                %                 for itimes=timeNos
                %                     wind = [table.t1(itimes) table.t2(itimes)];
                %                     idx_wind = ss1.getIndexForWindow(wind);
                %                     for istate = states
                %                         idx_state = ss1.getIndexForState(istate);
                %                         idx=idx_wind&idx_state;
                %                         ch=ch.getIdxPoints(idx);
                %                         powerspectrum=ch.getPSpectrum;
                %                     end
                %                     [powerSpecs(ifile,itimes) fnames{itimes}] = sdd.plot(channel,wind,true);
                %                     close
                %                 end
                %
            end
        end
        function outputArg = plotSDvsNSD(obj,timeNos)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            try close('PS Compare');catch,end;f=figure('Name','PS Compare','Units','normalized','Position', [0 0 1 1]);
            s=obj.PowerSpecs;
            tfmap=s.tfmat;
            conds=s.conds;
            timestr=s.timestr;
            f=s.fpoints;
            clear s;
            stateNos=[1 2 3 4 6];
            color_ses(1,:,:)=flipud(othercolor('OrRd9',6));
            color_ses(2,:,:)=flipud(othercolor('Blues9',6));
            states={'ALL','A-WAKE','Q-WAKE','SWS','REM'};
            for itime=1:numel(timestr)
                for istate=1:5
                    ax=subplot(5,numel(timestr),(istate-1)*numel(timestr)+itime);hold on;
                    ax.Position=[ax.Position(1)...
                        ax.Position(2)...
                        ax.Position(3)*1.1...
                        ax.Position(4)*1.25];
                    stateNo=stateNos(istate);
                    thetfmap=squeeze(tfmap(:,itime,stateNo,:));
                    if itime==1&&istate==1
                        baseline=thetfmap;
                    end
                    for icond=1:numel(conds)
                        sessions=squeeze(thetfmap(icond,:));
                        bsessions=squeeze(baseline(icond,:));
                        for isession=1:numel(sessions)
                            session=sessions{isession};
                            session(session==-inf|session==inf)=nan;
                            bsession=bsessions{isession};
                            bsession(bsession==-inf|bsession==inf)=nan;
                            mses=mean(session,'omitnan');
                            bmses=mean(bsession,'omitnan');
                            if ~isnan(  mses)
                                try
                                    yyaxis left;
                                    p1l=semilogx(ax,f,(mses-bmses)./bmses,'Color',...
                                        color_ses(icond,isession,:),'LineStyle','-',...
                                        'LineWidth',1);
                                    plotsesl(isession,icond)=p1l;
                                    yyaxis right;
                                    p1r=semilogx(ax,f,mses,'Color',color_ses(icond,isession,:),...
                                        'LineStyle',':','LineWidth',1);
                                    p1r.LineStyle=':';
                                    plotsesr(isession,icond)=p1r;
                                catch
                                end
                            end
                        end
                    end
                    %                     ax.XLim=[20 250];
                    yyaxis left
                    ax.YLim=[-.25 .25];
                    
                    yyaxis right
                    ax.YLim=[10 50];
                    ax.XGrid='on';
                    ax.YGrid='on';
                    
                    if itime~=1
                        %                         ax.YTickLabel=[];
                    else
                        yyaxis left
                        ylabel(states{istate});
                    end
                    %                     if istate~=5
                    %                         ax.XTickLabel=[];
                    %                     else
                    xlabel(timestr{itime});
                    
                    %                     end
                    ax.XScale='log';
                    try
                        legend(plotsesl(:),'SD AG Day1','SD AG Day3','NSD AG Day2','NSD AG Day4','Location','best')
                    catch
                    end
                    clear plotsesl
                end
            end
            fs=FigureFactory.instance;
            fs.save('PowerSpecs');
        end
        
        function []=plotPhasePrecession(obj)
            track1=obj.track;
            z=track1.Z./5;
            time=["13:20","14:55"];
            try close(1); catch, end;f=figure(1);
            f.Units='normalized';
            f.Position=[0 0.4 1 .2];
            %             subplot(4,1,1:3);hold on;
            z1=z.getTimeWindowForAbsoluteTime(time);
            track1=z1.getLowpassFiltered(.2);
            dx=diff(track1.getVoltageArray);
            ticd_track=track1.getTimeIntervalCombined;
            dt=diff(ticd_track.getTimePointsInSec);
            speed=dx./dt;
            speed=[speed(1) speed];
            speed_ch=Channel(track1.getChannelName,speed,ticd_track);
            yyaxis right
            ps=speed_ch.plot;
            ps.LineWidth=1.5;
            
            not_running=speed_ch<5 & speed_ch>-5;
            speedEdges=diff(~not_running);
            startRunnig=find(speedEdges==1);
            stopRunning=find(speedEdges==-1);
            trackall=track1;track1(not_running)=nan;
            loc=trackall.getVoltageArray;
            locAtStartRunning=loc(startRunnig);
            locAtStopRunning=loc(stopRunning);
            runDirectionLeft=(locAtStopRunning-locAtStartRunning)<0;
            amountOfWayRun=abs(locAtStopRunning-locAtStartRunning);
            longruns_idx=amountOfWayRun>100;
            longRunStart_abs=startRunnig(longruns_idx);
            longRunStart_abs(20)=[];
            longRunStop_abs=stopRunning(longruns_idx);
            longRunStop_abs(20)=[];
            
            longRundirectionsLeft=runDirectionLeft(longruns_idx);
            longRundirectionsLeft(20)=[];
            
            runningLeft=zeros(numel(not_running),1);
            runningRight=zeros(numel(not_running),1);
            runningNo=zeros(numel(not_running),1);
            for iperiod=1:numel(longRunStart_abs)
                runperiod=longRunStart_abs(iperiod):longRunStop_abs(iperiod);
                if longRundirectionsLeft(iperiod)
                    runningLeft(runperiod)=1;
                else
                    runningRight(runperiod)=1;
                end
                runningNo(runperiod)=iperiod;
            end
            trackLeft=track1;
            trackRight=track1;
            trackLeft(~runningLeft)=nan;
            trackRight(~runningRight)=nan;
            yyaxis left;hold on;
            pt=trackLeft.plot;
            pt.LineWidth=1.5;
            pt.LineStyle='-';
            pt=trackRight.plot;
            pt.LineWidth=1.5;
            pt.LineStyle='-';
            
            sdd=obj.Sdd;
            ch1=sdd.getLFP(1,1);
            ch11=ch1.getTimeWindowForAbsoluteTime(time);
            freqband=8;
            tfm=ch11.getTimeFrequencyMap(TimeFrequencyWavelet(freqband));
            phase=tfm.getPhase(freqband);
            power=tfm.getPower(freqband);
            
            %             subplot(4,1,4)
            power_mf=power.getMeanFiltered(5);
            power_mf=power_mf.getZScored;
            power_mf_ds=power_mf.getDownSampled(1).*20-60;
            yyaxis left;hold on;
            pp=power_mf_ds.plot('-k');
            pp.LineWidth=2;
            ax=gca;
            ax.YLim=[min(track1.getVoltageArray) max(track1.getVoltageArray)];
            
            bcs=obj.bc;
            swr=bcs.calculateSWR;
            [ripple_times, y]=swr.getRipplesTimesInWindow(time);
            s=scatter(ripple_times, y,'filled');
            s.AlphaData=ones(numel(y),1)*.5;
            s.SizeData=20;s.MarkerFaceAlpha='flat';
            fig=FigureFactory.instance;
            fig.save('Track_speed_theta')
            
            try close(3); catch, end;f=figure(3);
            f.Units='normalized';
            f.Position=[0 0.4 .7 .2];
            subplot(1,5,1:4);hold on;
            longRunStart_adj=ticd_track.adjustTimestampsAsIfNotInterrupted(longRunStart_abs);
            longRunStop_adj=ticd_track.adjustTimestampsAsIfNotInterrupted(longRunStop_abs);
            longRunStart_abs=seconds(longRunStart_adj/ticd_track.getSampleRate)+ticd_track.getStartTime;
            longRunStop_abs=seconds(longRunStop_adj/ticd_track.getSampleRate)+ticd_track.getStartTime;
            duration=seconds(longRunStop_abs-longRunStart_abs);
            before=35;after=30;
            for irun=1:numel(longRunStart_abs)
                aRunStart=longRunStart_abs(irun);
                aRunStop=longRunStop_abs(irun);
                periodAroundStart=power_mf.getTimeWindowForAbsoluteTime([...
                    aRunStart-seconds(before) aRunStart+seconds(after)]);
                periodAroundStop=power_mf.getTimeWindowForAbsoluteTime([...
                    aRunStop-seconds(before) aRunStop+seconds(after)]);
                periodAroundStart.plot('LineWidth',1.5);
                thetaPowerStart(irun,:)=periodAroundStart.getVoltageArray;
                thetaPowerStop(irun,:)=periodAroundStop.getVoltageArray;
                xline(aRunStart);
                xline(aRunStop);
            end
            ax=gca;
            ax.XLim=[ax.XLim(1)+minutes(8) ax.XLim(1)+minutes(15)];
            ylabel('Theta Power (z-scored)');
            
            subplot(2,5,5);hold on
            ticd=periodAroundStart.getTimeIntervalCombined;
            tinSec=ticd.getTimePointsInSec;
            t=tinSec-tinSec(1)-before;
            plot(t,thetaPowerStart,'LineWidth',.5,'Color',[.8 .8 .8]);
            shadedErrorBar(t,mean(thetaPowerStart),std(thetaPowerStart)/...
                sqrt(size(thetaPowerStart,1)));
            ax=gca;
            ax.YLim=[-.7 1.5];
            ax.XLim=[-before+15 after-15];
            yline(0);
            xline(0); text(0,ax.YLim(1),'Run','Rotation',90)
            xline(mean(duration),'--');text(mean(duration),ax.YLim(1),...
                'Stop','Rotation',90)
            ylabel('Theta Power (z-scored)');
            
            
            subplot(2,5,10);hold on
            ticd=periodAroundStop.getTimeIntervalCombined;
            tinSec=ticd.getTimePointsInSec;
            t=tinSec-tinSec(1)-before;
            plot(t,thetaPowerStop,'LineWidth',.5,'Color',[.8 .8 .8]);
            shadedErrorBar(t,mean(thetaPowerStop),std(thetaPowerStop)/...
                sqrt(size(thetaPowerStop,1)));
            ax=gca;
            ax.YLim=[-.7 1.5];
            ax.XLim=[-before+15 after-15];
            yline(0);
            xline(0);text(0,ax.YLim(1),'Stop','Rotation',90)
            xline(-mean(duration),'--');text(-mean(duration),ax.YLim(1),...
                'Run','Rotation',90)
            ylabel('Theta Power (z-scored)');
            l=xlabel('Time(s)','HorizontalAlignment','right');
            l.HorizontalAlignment='right';
            l.Position(1)=ax.XLim(2);
            
            sa=obj.Sa.getTimeInterval(time);
            sus=sa.getSpikeUnits;
            fig=FigureFactory.instance;
            fig.save('Run_theta')
            close all
            for iunit=1:numel(sus)
                su=sus(iunit);
                times_phase=phase.getTimeInterval;
                phaseValues=phase.getVoltageArray;
                times_track=track1.getTimeInterval;
                trackLocationLeft=trackLeft.getVoltageArray;
                trackLocationRight=trackRight.getVoltageArray;
                spktimes=su.getAbsoluteSpikeTimes;
                
                idx=times_track.getSampleFor(spktimes);
                locsLeft=trackLocationLeft(idx);
                locsRight=trackLocationRight(idx);
                active_idxLeft=~isnan(locsLeft);
                active_idxRight=~isnan(locsRight);
                locs_actives{1}=locsLeft(active_idxLeft);
                locs_actives{2}=locsRight(active_idxRight);
                idxL=times_phase.getSampleFor(spktimes(active_idxLeft));
                idxR=times_phase.getSampleFor(spktimes(active_idxRight));
                phases_actives{1}=phaseValues(idxL);
                phases_actives{2}=phaseValues(idxR);
                titles=["Running to Left","Running to Right"];
                if numel(idxL)>30||numel(idxR)>30
                    try
                        try close(2);catch, end;f=figure(2);
                        f.Units='normalized';
                        f.Position=[0 .3 .35 .50];
                        for idir=1:2
                            phases_active=phases_actives{idir};
                            locs_active=locs_actives{idir};
                            subplot(4,2,[0 2]+idir);
                            s=polarscatter(phases_active,locs_active,'filled');
                            s.SizeData=30;
                            s.AlphaData=ones(numel(locs_active),1)*.5;
                            s.MarkerFaceAlpha='flat';
                            ax=gca;
                            ax.RLim=[-200 100];
                            ax.RTick=[-100 0 100];
                            mu=circ_mean(phases_active');
                            r=circ_r(phases_active');
                            [pval, z]=circ_rtest(phases_active');
                            hold on;
                            zm = r*exp(1i*mu);
                            pp=polarplot([0 mu],[-200 r*300-200]);
                            pp.LineWidth=3;
                            pp.Color='r';
                            [rho pval1] = circ_corrcl(phases_active, locs_active);
                            text(0,-200,sprintf('z= %.3f\np= %.3f\n\nrho=%.3f\np=%.3f'...
                                ,z,pval,rho,pval1),'HorizontalAlignment','center')
                            
                            clusterinfo=sa.ClusterInfo;
                            gr=clusterinfo(clusterinfo.id==su.Id,:).group;
                            loc=clusterinfo(clusterinfo.id==su.Id,:).location{:};
                            shank=clusterinfo(clusterinfo.id==su.Id,:).sh;
                            channel=clusterinfo(clusterinfo.id==su.Id,:).ch;
                            text(pi/4,120,sprintf('Id= %d, %s, %s\nshank= %d, channel= %d',su.Id,loc,gr,shank,channel),'HorizontalAlignment','left')
                            title1=text(pi/2,150,titles{idir});title1.HorizontalAlignment='center';
                            title1.FontSize=12;title1.FontWeight='bold';
                            ax1=axes;
                            ax1.Position=ax.Position;
                            ph=polarhistogram(phases_active,12,'Normalization','pdf','DisplayStyle','stairs');
                            ax1=gca;
                            ax1.Visible='off';
                            ph.LineWidth=2;
                            ph.EdgeAlpha=.5;ph.EdgeColor='r';
                            
                            subplot(5,2,[6]+idir);
                            s1=scatter(locs_active,phases_active,'filled');
                            s1.SizeData=30;
                            s1.AlphaData=ones(numel(locs_active),1)*.5;
                            s1.MarkerFaceAlpha='flat';
                            ax=gca;
                            ax.YLim=[-pi pi];
                            ax.XLim=[-100 100];
                            title('');
                            legend off;
                            xlabel('Location (cm)');
                            ylabel('Theta Phase (rad)');
                            ax_=axes;
                            ax_.Position=ax.Position;
                            ax_.Position(2)=ax_.Position(2)-ax_.Position(4);
                            s1=scatter(locs_active,phases_active,'filled');
                            s1.SizeData=30;
                            s1.AlphaData=ones(numel(locs_active),1)*.5;
                            s1.MarkerFaceAlpha='flat';
                            ax_.YLim=[-pi pi];
                            ax_.XLim=[-100 100];
                            
                            ax_.Visible='off';
                           
                            ax1=axes;
                            ax1.Position=ax.Position;
                            ax1.Position(2)=ax1.Position(2)+ax1.Position(4);
                            ax1.Position(4)=.08;
                            h1=histogram(locs_active);
                            h1.BinEdges=-100:5:100;
                            ax1.XLim=[-100 100];
                            ax1.Visible='off';
                            
                        end
                        fig.save(['PhasePrecession_' num2str(su.Id)])
                    catch
                    end
                end
            end
        end
    end
end


