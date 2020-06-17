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
        function obj = TimeInterval(startTime, sampleRate,numberOfPoints)
            %INTERVAL Construct an instance of this class
            %   Detailed explanation goes here
            obj.SampleRate = sampleRate;
            obj.StartTime=startTime;
            obj.NumberOfPoints=numberOfPoints;
            obj.Format='dd-MMM-uuuu HH:mm:ss.SSS';
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
                warning('End sample is > number of point is TimeInterval %d, \n\tit is set that.\n', obj.NumberOfPoints)
            end
            if startSample>0 && startSample<=endSample && endSample<=obj.NumberOfPoints
                timeInterval=TimeInterval(obj.getRealTimeFor(startSample),obj.SampleRate, endSample-startSample+1);
            else
                warning('Something wrong with the numbers. Please check if correct. \n\tNothing is returned.')
                timeInterval=[];
            end
        end
        function timeInterval=getTimeIntervalForTimes(obj,startTime,endTime)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if startTime<obj.StartTime
                startTime=obj.StartTime;
            end
            if endTime>obj.getEndTime
                endTime=obj.getEndTime;
            end
            startSample=obj.getSampleFor(startTime);
            endSample=obj.getSampleFor(endTime);
            timeInterval=obj.getTimeIntervalForSamples(startSample,endSample);
        end
        function time=getRealTimeFor(obj,sample)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if sample>0 && sample<obj.NumberOfPoints
                time=obj.StartTime+seconds((sample-1)/obj.SampleRate);
            else
                time=datetime('today');
                time.Format=obj.Format;
                warning('Sample is not in the TimeInterval -- should be between\n\t%d -- %d\nReturned ''%s''',1,obj.NumberOfPoints,datestr(time));
            end
            time.Format=obj.Format;
        end
        function sample=getSampleFor(obj,time)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if time>=obj.StartTime && time<=obj.getEndTime
                sample=round(seconds(time-obj.StartTime)*obj.SampleRate)+1;
            else
                warning('Time is not in the TimeInterval -- should be between\n\t%s -- %s\nReturned ''-1''',obj.StartTime,obj.getEndTime);
                sample=-1;
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
        function timeInterval=getDownsampled(obj,downsampleFactor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            timeInterval=TimeInterval(obj.StartTime,...
                round(obj.SampleRate/downsampleFactor),...
                round((obj.NumberOfPoints-1)/downsampleFactor)+1);
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
            ts=obj.getTimeSeries;
            tps=ts.Time;
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

