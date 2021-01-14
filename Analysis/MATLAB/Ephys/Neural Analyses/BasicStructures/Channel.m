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
            if numel(voltageArray)>timeIntervalCombined.getNumberOfPoints
                voltageArray=voltageArray(1:timeIntervalCombined.getNumberOfPoints);
            elseif numel(voltageArray)<timeIntervalCombined.getNumberOfPoints
                diff1=timeIntervalCombined.getNumberOfPoints-numel(voltageArray);
                voltageArray=[voltageArray zeros(diff1,1)];
            end
            obj@Oscillation(voltageArray,...
                timeIntervalCombined.getSampleRate);
            obj.ChannelName=channelname;
            obj.TimeIntervalCombined=timeIntervalCombined;
            
            fprintf(...
                'New Channel %s, lenght %d, %s -- %s, %dHz\n',...
                num2str(obj.ChannelName),numel(obj.getVoltageArray),...
                datestr(timeIntervalCombined.getStartTime),...
                datestr(timeIntervalCombined.getEndTime),...
                obj.sampleRate);
        end
        function chan=getChannelName(obj)
            chan=obj.ChannelName;
        end
        function st=getTimeIntervalCombined(obj)
            st=obj.TimeIntervalCombined;
        end
        function st=getTimeInterval(obj)
            st=obj.TimeIntervalCombined;
        end
        function ch=setTimeInterval(obj,ti)
            ch=Channel(obj.ChannelName,obj.voltageArray,ti);
        end
        
        function obj=getTimeWindowForAbsoluteTime(obj,window)
            ticd=obj.TimeIntervalCombined;
            [h,m,s]=hms(ticd.getStartTime);
            basetime=ticd.getStartTime-hours(h)-minutes(m)-seconds(s);
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
            ticd1=ticd.getTimeIntervalForTimes(time.start,time.end);
            obj.voltageArray=obj.voltageArray(sample.start:sample.end);
            obj.TimeIntervalCombined=ticd1;
        end
        
        function p=plot(obj,varargin)
            va=obj.getVoltageArray;
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

