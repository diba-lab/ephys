classdef RippleAbs
    %RIPPLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimeIntervalCombined
        DetectorInfo
    end
    methods (Abstract)
        getPeakTimes(obj)
    end
    methods

        
        function outputArg = plotScatterHoursInXAxes(obj)
            ticd=obj.TimeIntervalCombined;
            peaktimestamps=obj.PeakTimes*ticd.getSampleRate;
            peakTimeStampsAdjusted=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestamps);
            peakTimesAdjusted=peakTimeStampsAdjusted/ticd.getSampleRate;
            peakripmax=obj.RipMax(:,1);
            s=scatter(hours(seconds(peakTimesAdjusted)),peakripmax...
                ,'Marker','.','MarkerFaceAlpha',.7,'MarkerEdgeAlpha',.7,...
                'SizeData',50);
            
        end
        function outputArg = plotScatterAbsoluteTimeInXAxes(obj)
            ticd=obj.TimeIntervalCombined;
            peaktimestamps=obj.PeakTimes*ticd.getSampleRate;
            peakTimeStampsAdjusted=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestamps);
            peakTimesAdjusted=peakTimeStampsAdjusted/ticd.getSampleRate;
            peakripmax=obj.RipMax(:,1);
            s=scatter(seconds(peakTimesAdjusted)+ticd.getStartTime,peakripmax...
                ,'Marker','.','MarkerFaceAlpha',.7,'MarkerEdgeAlpha',.7,...
                'SizeData',50);
            
        end
        function [p2] = plotHistCount(obj, TimeBinsInSec)
            if ~exist('TimeBinsInSec','var')
                TimeBinsInSec=30;
            end
            ticd=obj.TimeIntervalCombined;
            peaktimestamps=obj.PeakTimes*ticd.getSampleRate;
            peakTimeStampsAdjusted=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestamps);
            peakTimesAdjusted=peakTimeStampsAdjusted/ticd.getSampleRate;
            [N,edges]=histcounts(peakTimesAdjusted,1:TimeBinsInSec:max(peakTimesAdjusted));
            t=hours(seconds(edges(1:(numel(edges)-1))+15));
            t1=linspace(min(t),max(t),numel(t)*10);
            N=interp1(t,N,t1,'spline','extrap');
            p2=plot(t1,N,'LineWidth',1);
        end
        
        function [ripples y]=getRipplesTimesInWindow(obj,toi)
            
            ticd=obj.TimeIntervalCombined;
            if isduration(toi)
                st=ticd.getStartTime;
                toi1=datetime(st.Year,st.Month,st.Day)+toi;
            else
                toi1=toi;
            end
            samples=ticd.getSampleFor(toi1);
            secs=samples/ticd.getSampleRate;
            idx=obj.PeakTimes>=secs(1)&obj.PeakTimes<=secs(2);
            pt1=obj.PeakTimes(idx);
            ripmax=obj.RipMax;
            y=ripmax(idx);
            if ~isempty(pt1)
                sample=pt1*ticd.getSampleRate;
                ripples=ticd.getRealTimeFor(sample);
            else
                ripples=[];
            end
            
        end
        function obj=getRipplesInWindow(obj,toi)
%             
%             ticd=obj.TimeIntervalCombined;
%             if isduration(toi)
%                 st=ticd.getStartTime;
%                 toi1=datetime(st.Year,st.Month,st.Day)+toi;
%             else
%                 toi1=toi;
%             end
%             samples=ticd.getSampleFor(toi1);
%             secs=samples/ticd.getSampleRate;
%             idx=obj.PeakTimes>=secs(1)&obj.PeakTimes<=secs(2);
%             ticd_new=obj.TimeIntervalCombined.getTimeIntervalForTimes(toi(1),toi(2));
%             dt=ticd_new.getStartTime-ticd.getStartTime;
% 
%             obj.PeakTimes=obj.PeakTimes(idx);
%             obj.PeakTimes-seconds(dt)
%             obj.RipMax=obj.RipMax(idx,:);
%             obj.SwMax=obj.SwMax(idx,:);
%             obj.TimeStamps=obj.TimeStamps(idx,:);
%             obj.TimeIntervalCombined
        end
        
        function obj = setTimeIntervalCombined(obj,ticd)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.TimeIntervalCombined=ticd;
        end
    end
end

