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
            stimes=spikeunit.getTimesInSecZT;
            ptimes=positionData.time.getTimePointsInSecZT;
            idxnan=isnan(table2array(positionData.data(:,1))');
            ptimes(1,idxnan)=nan;
            srate=max([1/spikeunit.Time.getSampleRate ...
                1/positionData.time.getSampleRate]);
            is1=1;
            stimes1=[];
            for is=1:numel(stimes)
                stime=stimes(is);
                minValue=min(abs(stime-ptimes),[],"omitnan");
                if abs(minValue)/2<srate
                    stimes1(is1)=stime; %#ok<AGROW> 
                    is1=is1+1;
                end                    
            end
            ticd=obj.Time;
            obj.TimesInSamples= seconds(seconds(stimes1)-(ticd.getStartTime - ...
                ticd.getZeitgeberTime))*ticd.SampleRate;
        end
        function [] = plotOnTimeTrack(obj,speedthreshold)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
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
                s1=scatter(Z(idx),timesmin(idx),50,color(round( ...
                    timeratio(idx)*10)+1,:),'filled');
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
        function [] = plotOnTrack2D(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            numPointsInPlot=50000;
            track=obj.PositionData;
            track.plot2D(numPointsInPlot);hold on

            if numel(obj.TimesInSamples)>0
                [~,idx]=track.getPositionForTimes(obj.getAbsoluteSpikeTimes);
                track.plot2DMark(idx);hold on
            end
        end
        function [] = plotSpikes2D(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            track=obj.PositionData;
            if numel(obj.TimesInSamples)>0
                [~,idx]=track.getPositionForTimes(obj.getAbsoluteSpikeTimes);
                track.plot2DMark(idx);hold on
            end
        end
        function [ax] = plotOnTrack3D(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            numPointsInPlot=50000;
            track=obj.PositionData;
            track.plot3Dtime(numPointsInPlot);hold on

            if numel(obj.TimesInSamples)>0
                [~,idx]=track.getPositionForTimes(obj.getAbsoluteSpikeTimes);
                track.plot3DMark(idx);hold on
            end
            ax=gca;
            ticd=obj.PositionData.time;
            t_org=ticd.getTimePointsInSec;
            ax.ZLim=[0 abs(t_org(2)-t_org(end))];
            ax.ZDir="reverse";
        end
        
        function [frm] = getFireRateMap(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            track=obj.PositionData;
            om=obj.PositionData.getOccupancyMap;
            [sTimes,~]=track.getPositionForTimes(obj.getAbsoluteSpikeTimes);
            frm=om+sTimes;
            frm.SpikeUnitTracked=obj;
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
            nGrid(1)=round((max(track.Z(idx_track))-min(track.Z(idx_track))) ...
                /SpatialBinSizeCM);
            nGrid(2)=round((max(track.X(idx_track))-min(track.X(idx_track))) ...
                /SpatialBinSizeCM);
            Smooth=.075;
            Tbin=1/30;
            TopRate=[];
            PFClassic(Pos(idx_track,:), SpkCnt(idx_track,:), Smooth, ...
                nGrid,Tbin,TopRate);
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
            nGrid(1)=round((max(track.Z(idx_track))-min(track.Z(idx_track))) ...
                /SpatialBinSizeCM);
            nGrid(2)=round((max(track.X(idx_track))-min(track.X(idx_track))) ...
                /SpatialBinSizeCM);
            Smooth=.075;
            Tbin=1/30;
            TopRate=[];
            PFClassic(Pos(idx_track,:), SpkCnt(idx_track,:), Smooth, ...
                nGrid,Tbin,TopRate);
            obj.addInfo(idx)
        end
    end
end

