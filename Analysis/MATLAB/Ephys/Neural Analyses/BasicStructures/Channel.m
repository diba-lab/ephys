classdef Channel < Oscillation & matlab.mixin.CustomDisplay
    %CHANNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        ChannelName
        TimeIntervalCombined
    end
    
    methods
        function obj = Channel(channelname, voltageArray, timeIntervalCombined)
            %CHANNEL Construct an instance of this class
            %   Detailed explanation goes here
            if size(voltageArray,1)>1
                voltageArray=voltageArray';
            end
            if numel(voltageArray)>timeIntervalCombined.getNumberOfPoints
                voltageArray=voltageArray(1:timeIntervalCombined.getNumberOfPoints);
            elseif numel(voltageArray)<timeIntervalCombined.getNumberOfPoints
                diff1=timeIntervalCombined.getNumberOfPoints-numel(voltageArray);
                voltageArray=[voltageArray zeros(1,diff1)];
            end
            obj@Oscillation(voltageArray,...
                timeIntervalCombined.getSampleRate);
            try
                obj.ChannelName=channelname;
            catch
            end
            try
                obj.TimeIntervalCombined=timeIntervalCombined;
            catch
            end
            fprintf(...
                'New Channel %s, lenght %d, %s -- %s, %dHz\n',...
                num2str(obj.ChannelName),numel(obj.getValues),...
                datestr(timeIntervalCombined.getStartTime),...
                datestr(timeIntervalCombined.getEndTime),...
                obj.SampleRate);
        end
        function st=getStartTime(obj)
            ti=obj.getTimeInterval;
            st=ti.getStartTime;
        end
        function en=getEndTime(obj)
            ti=obj.getTimeInterval;
            en=ti.getEndTime;
        end
        function len=getLength(obj)
            ti=obj.getTimeInterval;
            len=seconds(ti.getNumberOfPoints/ti.getSampleRate);
        end
        function chan=getChannelName(obj)
            chan=obj.ChannelName;
        end
        function obj=setChannelName(obj,name)
            obj.ChannelName=name;
        end
        function st=getTimeIntervalCombined(obj)
            st=obj.TimeIntervalCombined;
        end
        function st=getTimeInterval(obj)
            st=obj.TimeIntervalCombined;
        end
        function ch=setTimeInterval(obj,ti)
            ch=Channel(obj.ChannelName,obj.Values,ti);
        end
        
        function obj=getTimeWindowForAbsoluteTime(obj,window)
            ticd=obj.TimeIntervalCombined;
            basetime=ticd.getDate;
            if isstring(window)
                window1=datetime(window,'Format','HH:mm');
                add1(1)=hours(window1(1).Hour)+minutes(window1(1).Minute);
                add1(2)=hours(window1(2).Hour)+minutes(window1(2).Minute);
                time.start=basetime+add1(1);
                time.end=basetime+add1(2);
            elseif isduration(window)
                add1=window;
                time.start=basetime+add1(1);
                time.end=basetime+add1(2);
            elseif isdatetime(window)
                time.start=window(1);
                time.end=window(2);
            end
            sample.start=ticd.getSampleFor(time.start);
            sample.end=ticd.getSampleFor(time.end);
            ticd1=ticd.getTimeIntervalForTimes([time.start,time.end]);
            obj.Values=obj.Values(sample.start:sample.end);
            obj.TimeIntervalCombined=ticd1;
        end
        function obj=getTimeWindow(obj,windows)
            ticd=obj.TimeIntervalCombined;
            basetime=ticd.getDate;
            for iwind=1:size(windows,1)
                window=windows(iwind,:);
                if isstring(window)
                    window1=datetime(window,'Format','HH:mm');
                    add1(1)=hours(window1(1).Hour)+minutes(window1(1).Minute);
                    add1(2)=hours(window1(2).Hour)+minutes(window1(2).Minute);
                    time(iwind,1)=basetime+add1(1);
                    time(iwind,2)=basetime+add1(2);
                elseif isduration(window)
                    add1=window;
                    time(iwind,1)=basetime+add1(1);
                    time(iwind,2)=basetime+add1(2);
                elseif isdatetime(window)
                    time(iwind,1)=window(1);
                    time(iwind,2)=window(2);
                end
            end
            sample=ticd.getSampleFor(time);
            ticd1=ticd.getTimeIntervalForTimes(time);
            samples=[];
            for iwind=1:size(sample,1)
                thesamples=sample(iwind,1):sample(iwind,2);
                samples=horzcat(samples,thesamples);
            end
            obj.Values=obj.Values(samples);
            obj.TimeIntervalCombined=ticd1;
        end
        
        function p=plot(obj,varargin)
            va=obj.getValues;
            t=obj.TimeIntervalCombined;
            t_s=t.getTimePointsInSec;
            diff1=numel(t_s)-numel(va);
            va((numel(va)+1):(numel(va)+diff1))=zeros(diff1,1);
            t_s=t.getStartTime+seconds(t_s);
            p=plot(t_s,va(1:numel(t_s)),varargin{:});
        end
        function obj=plus(obj,aChan)
            obj.TimeIntervalCombined=obj.TimeIntervalCombined+aChan.getTimeInterval;
            obj.voltageArray=[obj.getVoltageArray ;aChan.voltageArray];
        end
        function ets=getTimeSeries(obj)
            ets=EphysTimeSeries(obj.getValues,obj.getSampleRate,obj.ChannelName);
        end
        
    end
    methods (Access = protected)
        function header = getHeader(obj)
            if ~isscalar(obj)
                header = getHeader@matlab.mixin.CustomDisplay(obj);
            else
                headerStr = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                headerStr = [headerStr,' with Customized Display'];
                header = sprintf('%s\n',headerStr);
            end
        end
    end
end

