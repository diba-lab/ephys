classdef SpikeUnitTracked < neuro.spike.SpikeUnit
    %SPIKEUNITTRACKED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        PositionData
    end

    methods
        function obj = SpikeUnitTracked(spikeunit,positionData)
            %SPIKEUNITTRACKED Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@neuro.spike.SpikeUnit(spikeunit);
            obj.PositionData=positionData;
        end
        function [] = plotOnTimeTrack(obj,speedthreshold)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            speedTrack=obj.PositionData.getSpeed;
            alpha=.3;
            track=obj.PositionData;
            track.plotZ;hold on
            times=obj.getAbsoluteSpikeTimes;
            timesmin=minutes(times-track.time.getStartTime);
            timeratio=timesmin./...
                minutes(track.time.getEndTime-track.time.getStartTime);
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
        function [] = plotOnTrack(obj,speedthreshold)
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
        function [] = plotPlaceFieldBoth(obj,speedthreshold)
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
        function [] = plotPlaceFieldNeg(obj,speedthreshold)
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
        function [] = plotPlaceFieldPos(obj,speedthreshold)
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
    end
end

