classdef TimeInterval
    %INTERVAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SampleRate
        StartTime
        NumberOfPoints
        Format
    end
    
    methods
        function obj = TimeInterval(startTime, sampleRate, numberOfPoints)
            %INTERVAL Construct an instance of this class
            %   Detailed explanation goes here
            obj.SampleRate = sampleRate;
            obj.StartTime=startTime;
            obj.NumberOfPoints=numberOfPoints;
%             obj.Format='dd-MMM-uuuu HH:mm:ss.SSS';
            obj.Format='HH:mm:ss.SSS';
        end
        
        function []=print(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            date=datestr(obj.getDate,1);
            st=datestr( obj.getStartTime,13);
            en=datestr(obj.getEndTime,13);
            dur=obj.getEndTime-obj.getStartTime;
            dur1=datestr(dur,13);
            sf=obj.getSampleRate;
            np=obj.getNumberOfPoints;
            jf=java.text.DecimalFormat; % comma for thousands, three decimal places
            np1= char(jf.format(np)); % omit "char" if you want a string out
            
            fprintf('\n\t%s <%s> <%s (%dHz)> \n\t%s %s\n',st,dur1,np1,sf,en,date);
        end
        function timeInterval=getTimeIntervalForSamples(obj, startSample, endSample)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if startSample <1
                startSample=1;
                warning('Start sample is <1, \n\tit is set to ''1''\n')
            end
            if endSample > obj.NumberOfPoints
                endSample=obj.NumberOfPoints;
            end
            if startSample>0 && startSample<=endSample && endSample<=obj.NumberOfPoints
                timeInterval=TimeInterval(obj.getRealTimeFor(startSample),obj.SampleRate, endSample-startSample+1);
            else
                timeInterval=[];
            end
        end
        function timeIntervals=getTimeIntervalForTimes(obj,windows)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for iwind=1:size(windows,1)
                window=windows(iwind,:);
                if window(1)<obj.getStartTime
                    window(1)=obj.obj.getStartTime;
                end
                if window(2)>obj.getEndTime
                    window(2)=obj.getEndTime;
                end
                windsample=obj.getSampleFor(window);
                try
                    timeIntervals=timeIntervals+obj.getTimeIntervalForSamples(windsample(1),windsample(2));
                catch
                    timeIntervals=obj.getTimeIntervalForSamples(windsample(1),windsample(2));
                end
            end
        end
        function time=getRealTimeFor(obj,samples)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            idx=samples>0 & samples<=obj.NumberOfPoints;
            for icol=1:size(idx,2)
                validsamples(:,icol)=samples(idx(:,icol),icol);
            end
            time=obj.StartTime+seconds(double((validsamples-1))/obj.SampleRate);
            time.Format=obj.Format;
            
            if sum(~idx)
                warning('Sample is not in the TimeInterval -- should be between\n\t%d -- %d\n'...
                    ,1,obj.NumberOfPoints);
            end
        end
        function samples=getSampleFor(obj,times)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            samples=nan(size(times));
            st=obj.StartTime;
            en=obj.getEndTime;
            for i=1:numel(times)
                time=times(i);
                if time>=st && time<=en
                    samples(i)=round(seconds(time-obj.StartTime)*obj.SampleRate)+1;
                end
            end
        end
        function time=getEndTime(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            time=obj.StartTime+seconds((obj.NumberOfPoints-1)/obj.SampleRate);
            time.Format=obj.Format;
        end
        function timeIntervalCombined=plus(obj,timeInterval)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            timeIntervalCombined=TimeIntervalCombined(obj,timeInterval);
        end
        function [timeInterval,residual]=getDownsampled(obj,downsampleFactor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            newnumPoints=floor(obj.NumberOfPoints/downsampleFactor);
            residual=mod(obj.NumberOfPoints,downsampleFactor);
            timeInterval=TimeInterval(obj.StartTime,...
                round(obj.SampleRate/downsampleFactor),...
                newnumPoints);
        end
        function plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ts=obj.getTimeSeriesDownsampled(obj.SampleRate);
            p1=ts.plot;
            p1.LineWidth=5;
        end
        function st=getStartTime(obj)
            st=obj.StartTime;
            st.Format=obj.Format;
        end
        function tps=getTimePointsInSec(obj)
            tps=0:(1/obj.SampleRate):((obj.NumberOfPoints-1)/obj.SampleRate);
        end
        function tps=getTimePointsInAbsoluteTimes(obj)
            tps=seconds(obj.getTimePointsInSec)+obj.getStartTime;
        end
        function nop=getNumberOfPoints(obj)
            nop=obj.NumberOfPoints;
        end
        function sr=getSampleRate(obj)
            sr=obj.SampleRate;
        end
        function arrnew=adjustTimestampsAsIfNotInterrupted(obj,arr)
            arrnew=arr;
        end
        function ticd=saveTable(obj,filePath)
            S.StartTime=obj.StartTime;
            S.NumberOfPoints=obj.NumberOfPoints;
            S.SampleRate=obj.SampleRate;
            T=struct2table(S);
            writetable(T,filePath)
            ticd=TimeIntervalCombined(filePath);
        end
        function date=getDate(obj)
            st=obj.getEndTime;
            date=datetime( st.Year,st.Month,st.Day);
        end

    end
    methods (Access=private)
        function ts=getTimeSeries(obj)
            ts=timeseries(ones(obj.NumberOfPoints,1));
            ts.TimeInfo.Units='seconds';
            ts=ts.setuniformtime('StartTime', 0,'Interval',1/obj.SampleRate);
            ts.TimeInfo.StartDate=obj.StartTime;
            ts.TimeInfo.Format='HH:MM:SS.FFF';
        end
        function ts=getTimeSeriesDownsampled(obj,downsampleFactor)
            ts=timeseries(ones(round(obj.NumberOfPoints/downsampleFactor),1));
            ts.TimeInfo.Units='seconds';
            ts=ts.setuniformtime('StartTime', 0,'Interval',1/obj.SampleRate*downsampleFactor);
            ts.TimeInfo.StartDate=obj.StartTime;
            ts.TimeInfo.Format='HH:MM:SS.FFF';
        end

    end
end

