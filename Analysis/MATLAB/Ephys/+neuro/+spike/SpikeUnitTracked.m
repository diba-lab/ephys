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
            if nargin>0
                fnames=fieldnames(spikeunit);
                for ifn=1:numel(fnames)
                    fn=fnames{ifn};
                    try
                        obj.(fn)=spikeunit.(fn);
                    catch ME
                        
                    end
                end
                obj.PositionData=positionData;
                stimes=seconds(spikeunit.getTimesZT);
                ptimes=seconds(positionData.time.getTimePointsZT)';
                idxnan=isnan(table2array(positionData.data(:,1)));
                ptimes(idxnan)=nan;
                srate=max([1/spikeunit.Time.getSampleRate ...
                    1/positionData.time.getSampleRate]);
                is1=1;
                stimes1=[];
                for is=1:numel(stimes)
                    stime=stimes(is);
                    minValue=min(abs(stime-ptimes),[],"omitnan");
                    if minValue<srate/2
                        stimes1(is1)=stime; %#ok<AGROW>
                        is1=is1+1;
                    else

                    end
                end
                ticd=obj.Time;
                secondsFromRecordBeginnig=seconds(seconds(stimes1)- ...
                    (ticd.getStartTime - ticd.getZeitgeberTime));
                samples=uint64(secondsFromRecordBeginnig*ticd.SampleRate)';
                obj.TimesInSamples= samples;
            end
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
            [X,Y,Z,idx]=track.getLocationForTimesBoth( ...
                times,speedthreshold);
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
        function [] = plotOnTrack2D(obj,color)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            numPointsInPlot=50000;
            track=obj.PositionData;
            track.plot2D(numPointsInPlot);hold on

            if numel(obj.TimesInSamples)>0
                [~,idx]=track.getPositionForTimes( ...
                    obj.getAbsoluteSpikeTimes);
                track.plot2DMark(idx,color);hold on
            end
        end
        function [] = plotSpikes2D(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            track=obj.PositionData;
            if numel(obj.TimesInSamples)>0
                [~,idx]=track.getPositionForTimes( ...
                    obj.getAbsoluteSpikeTimes);
                track.plot2DMark(idx);hold on
            end
        end
        function [ax] = plotOnTrack3D(obj,color)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            numPointsInPlot=50000;
            track=obj.PositionData;
            track.plot3DtimeContinuous(numPointsInPlot);hold on

            if numel(obj.TimesInSamples)>0
                [~,idx]=track.getPositionForTimes( ...
                    obj.getAbsoluteSpikeTimes);
                track.plot3DMark(idx,color);hold on
            end
            ax=gca;
            ticd=obj.PositionData.time;
            t_org=seconds(ticd.getTimePoints);
            ax.ZLim=[0 abs(t_org(2)-t_org(end))];
            ax.ZDir="reverse";
        end
        
        function [frm] = getFireRateMap(obj,xedges,zedges)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            track=obj.PositionData;
            if nargin>1
                om=obj.PositionData.getOccupancyMap(xedges,zedges);
            else
                om=obj.PositionData.getOccupancyMap();
            end
            [sTimes,~]=track.getPositionForTimes( ...
                obj.getAbsoluteSpikeTimes);
            frm=om+sTimes;
            frm.SpikeUnitTracked=obj;
        end
        function [tall] = getSpikePositionTable(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            track=obj.PositionData;
            
            [sTimes,~]=track.getPositionForTimes( ...
                obj.getAbsoluteSpikeTimes);
            t1=seconds(obj.getTimesZT)';
            t2=array2table(t1,VariableNames={'TimeZT'});
            tall=[sTimes t2];
        end
    end
end

