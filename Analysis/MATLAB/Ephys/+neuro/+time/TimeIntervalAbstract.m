classdef TimeIntervalAbstract
    %TIMEINTERVALINTERFACE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Format
    end
    
    methods (Abstract)
        print(obj)
        getTimeIntervalForSamples(obj, startSample, endSample)
        getTimeIntervalForTimes(obj, windows)
        getTimeIntervalList(obj)
        getRealTimeFor(obj, samples)
        getSampleFor(obj, times)
        getEndTime(obj)
        plus(obj, timeInterval)
        getDownsampled(obj, downsampleFactor)
        plot(obj)
        getStartTime(obj)
        getTimePoints(obj)
        getTimePointsInAbsoluteTimes(obj)
        getNumberOfPoints(obj)
        getSampleRate(obj)
        adjustTimestampsAsIfNotInterrupted(obj, arr)
        saveTable(obj, filePath)
        shiftTimePoints(obj,duration)
    end
    methods 
        function ts=getTimeSeries(obj)
            ts=timeseries(ones(obj.getNumberOfPoints,1));
            ts.TimeInfo.Units='seconds';
            ts=ts.setuniformtime('StartTime', 0,'Interval',1/obj.getSampleRate);
            ts.TimeInfo.StartDate=obj.getStartTime;
            ts.TimeInfo.Format='HH:MM:SS.FFF';
        end
        function ts=getTimeSeriesDownsampled(obj,downsampleFactor)
            ts=timeseries(ones(round(obj.getNumberOfPoints/downsampleFactor),1));
            ts.TimeInfo.Units='seconds';
            ts=ts.setuniformtime('StartTime', 0,'Interval',1/obj.getSampleRate*downsampleFactor);
            ts.TimeInfo.StartDate=obj.getStartTime;
            ts.TimeInfo.Format='HH:MM:SS.FFF';
        end
        function dt=convertDurationToDatetime(obj,time)
            st=obj.getStartTime;
            dt=datetime(st.Year,st.Month,st.Day)+time;
        end
        function dt=convertStringToDatetime(obj,time)
            st=obj.getStartTime;
            try 
                dt1=datetime(time);
            catch
                dt1=datetime(time,'InputFormat','HH:mm');
            end
            dt=datetime(st.Year,st.Month,st.Day)+hours(dt1.Hour)+minutes(dt1.Minute)+seconds(dt1.Second);
        end
        function times=getDatetime(obj,times)
            % Convert times of duration or string('HH:mm') to datetime format.
            if ~isdatetime(times)
                if isduration(times)
                    times=obj.convertDurationToDatetime(times);
                elseif isa(times,"neuro.time.Relative")
                    times=times.pointsAbsolute;           
                elseif isa(times,"neuro.time.ZeitgeberTime")
                    times=times.pointsAbsolute;
                elseif isa(times,"neuro.time.Absolute")
                    times=times.points;
                elseif iscell(times)
                    if (isstring(times{1})||ischar(times{1}))
                        times = obj.convertStringToDatetime(times);
                    end
                else
                    if (isstring(times)||ischar(times))
                        times = obj.convertStringToDatetime(times);
                    end
                end
            end
        end
        function date=getDate(obj)
            st=obj.getEndTime;
            date=datetime( st.Year,st.Month,st.Day);
        end
        function tps=getTimePointsInSamples(obj)
            tps=1:obj.getNumberOfPoints;
        end
    end
end

