classdef SpikeUnit
    %SPIKEUNIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Id
        Times
        TimeIntervalCombined
        Info
    end
    
    methods
        function obj = SpikeUnit(spikeId,spikeTimes,timeIntervalCombined)
            %SPIKEUNIT Construct an instance of this class
            %   Detailed explanation goes here
            obj.Id = spikeId;
            obj.Times=spikeTimes;
            obj.TimeIntervalCombined=timeIntervalCombined;
        end
        
        function timesnew = getAbsoluteSpikeTimes(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ticd=obj.TimeIntervalCombined;
            timesnew=ticd.getRealTimeFor(double(obj.Times));
        end
        function times = getTimes(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=neuro.time.Sample(obj.Times, obj.TimeIntervalCombined.getSampleRate);
        end
        function obj = setInfo(obj,info)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Info=info;
        end
        function fireRate = getFireRate(obj,timebininsec)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            TimeBinsInSec=timebininsec;
            timesInSamples=obj.Times;
            til=obj.TimeIntervalCombined.getTimeIntervalList;
            endtimeinseclast=0;
            ticdnew=neuro.time.TimeIntervalCombined;
            for iti=1:til.length
                ti=til.get(iti);
                endtimeinsec=seconds(ti.getEndTime-ti.getStartTime);
                timesInSec=double(timesInSamples)/ti.getSampleRate-endtimeinseclast;
                endtimeinseclast=endtimeinseclast+endtimeinsec;
                N=histcounts(timesInSec,0:TimeBinsInSec:endtimeinsec)/TimeBinsInSec;
                if iti==1
                    Nres=N;
                else
                    Nres=[Nres N];
                end
                tinew=neuro.time.TimeIntervalZT(ti.getStartTime+seconds(TimeBinsInSec/2),1/(TimeBinsInSec),numel(N),ti.getZeitgeberTime);
                ticdnew=ticdnew+tinew;
            end
            fireRate=neuro.basic.Channel(num2str(obj.Id),Nres,ticdnew); %#ok<*CPROPLC>
        end
        function [] = plotOnTimeTrack(obj,track,speedthreshold)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            speedTrack=track.getSpeed;
            thresholded=speedTrack.getAboveAbs(5);
            alpha=.3;
            track.plotZ;hold on
            times=obj.getAbsoluteSpikeTimes;
            timesmin=minutes(times-track.timeIntervalCombined.getStartTime);
            timeratio=timesmin./...
                minutes(track.timeIntervalCombined.getEndTime-track.timeIntervalCombined.getStartTime);
            [X,Y,Z,idx]=track.getLocationForTimesBoth(times,speedthreshold);
            color=linspecer(11);
            try 
                s1=scatter(Z(idx),timesmin(idx),50,color(round(timeratio(idx)*10)+1,:),'filled');
                s2=scatter(Z(~idx),timesmin(~idx),5,[0 0 0],'filled');
            catch
                error
            end
            ax=gca;
            ax.YDir='reverse';
            legend off
            s1.MarkerFaceAlpha=alpha;
            s1.MarkerEdgeAlpha=alpha;
            s2.MarkerFaceAlpha=alpha/3;
            s2.MarkerEdgeAlpha=alpha/3;
            str=obj.addInfo(idx);
        end
        function [] = plotOnTrack(obj,track,speedthreshold)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            alpha=.1;
           
            track.plot2Dabove(speedthreshold);hold on
            times=obj.getAbsoluteSpikeTimes;
            timeratio=minutes(times-track.timeIntervalCombined.getStartTime)./...
                minutes(track.timeIntervalCombined.getEndTime-track.timeIntervalCombined.getStartTime);
            [X,Y,Z,idx]=track.getLocationForTimesBoth(times,speedthreshold);
            color=linspecer(11);
            try
                s=scatter(Z(idx),X(idx),50,color(round(timeratio(idx)*10)+1,:),'filled');
            catch
                error
            end
            ax=gca;
            try
                ax.YLim=[min(track.X) max(track.X)];
                ax.XLim=[min(track.Z) max(track.Z)];
            catch
                error
            end
            s.MarkerFaceAlpha=alpha;
            s.MarkerEdgeAlpha=alpha;
            str=obj.addInfo(idx);
        end
        function [] = plotPlaceFieldBoth(obj,track,speedthreshold)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=obj.getAbsoluteSpikeTimes;
            [~,~,~,idx]=track.getLocationForTimesBoth(times,speedthreshold);
            idx_track=track.getSpeed.getAboveAbs(speedthreshold);
            SpkCnt=track.getSpikeArray(times(idx));
            Pos1=[track.Z track.X];
            Pos = (Pos1 - min(Pos1)) ./ ( max(Pos1) - min(Pos1) );
            SpatialBinSizeCM=2;
            nGrid(1)=round((max(track.Z(idx_track))-min(track.Z(idx_track)))/SpatialBinSizeCM);
            nGrid(2)=round((max(track.X(idx_track))-min(track.X(idx_track)))/SpatialBinSizeCM);
            Smooth=.075;
            Tbin=1/30;
            TopRate=[];
            PFClassic(Pos(idx_track,:), SpkCnt(idx_track,:), Smooth, nGrid,Tbin,TopRate);
            obj.addInfo(idx)
        end
        function [] = plotPlaceFieldNeg(obj,track,speedthreshold)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=obj.getAbsoluteSpikeTimes;
            [~,~,~,idx]=track.getLocationForTimesNeg(times,speedthreshold);
            idx_track=track.getSpeed.getBelow(speedthreshold);
            SpkCnt=track.getSpikeArray(times(idx));
            Pos1=[track.Z track.X];
            Pos = (Pos1 - min(Pos1)) ./ ( max(Pos1) - min(Pos1) );
            SpatialBinSizeCM=2;
            nGrid(1)=round((max(track.Z(idx_track))-min(track.Z(idx_track)))/SpatialBinSizeCM);
            nGrid(2)=round((max(track.X(idx_track))-min(track.X(idx_track)))/SpatialBinSizeCM);
            Smooth=.075;
            Tbin=1/30;
            TopRate=[];
            PFClassic(Pos(idx_track,:), SpkCnt(idx_track,:), Smooth, nGrid,Tbin,TopRate);
            obj.addInfo(idx)
        end
        function [] = plotPlaceFieldPos(obj,track,speedthreshold)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=obj.getAbsoluteSpikeTimes;
            [~,~,~,idx]=track.getLocationForTimesPos(times,speedthreshold);
            idx_track=track.getSpeed.getAbove(speedthreshold);
            SpkCnt=track.getSpikeArray(times(idx));
            Pos1=[track.Z track.X];
            Pos = (Pos1 - min(Pos1)) ./ ( max(Pos1) - min(Pos1) );
            SpatialBinSizeCM=2;
            nGrid(1)=round((max(track.Z(idx_track))-min(track.Z(idx_track)))/SpatialBinSizeCM);
            nGrid(2)=round((max(track.X(idx_track))-min(track.X(idx_track)))/SpatialBinSizeCM);
            Smooth=.075;
            Tbin=1/30;
            TopRate=[];
            PFClassic(Pos(idx_track,:), SpkCnt(idx_track,:), Smooth, nGrid,Tbin,TopRate);
            obj.addInfo(idx)
        end
        function info=getInfo(obj,idx)
            
            info=sprintf(' ID:%d, nSpk:%d (of %d), Ch:%d',obj.Id,...
                numel(obj.Times(idx)),numel(obj.Times),obj.Channel);
            
        end
        function str=addInfo(obj,idx)
            str=obj.getInfo(idx);
            text(0,1,str,'Units','normalized','VerticalAlignment','bottom','HorizontalAlignment','left');
            
        end
    end
end

