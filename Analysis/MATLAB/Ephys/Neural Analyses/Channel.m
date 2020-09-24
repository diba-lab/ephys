classdef Channel < Oscillation
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
        obj@Oscillation(voltageArray, timeIntervalCombined.getSampleRate);
        obj.ChannelName=channelname;
        obj.TimeIntervalCombined=timeIntervalCombined;
        fprintf(...
            'New Channel %d, lenght %d, %s -- %s, %dHz\n',...
            obj.ChannelName,numel(obj.getVoltageArray),...
            datestr(timeIntervalCombined.getStartTime),...
            datestr(timeIntervalCombined.getEndTime),...
            obj.sampleRate)
        end
        function chan=getChannelName(obj)
            chan=obj.ChannelName;
        end
        function st=getTimeIntervalCombined(obj)
            st=obj.TimeIntervalCombined;
        end

        function obj=getTimeWindowForAbsoluteTime(obj,window)
            ticd=obj.TimeIntervalCombined;
            [h,m,s]=hms(ticd.getStartTime);
            basetime=ticd.getStartTime-hours(h)-minutes(m)-seconds(s);
            time.start=basetime+window(1);
            time.end=basetime+window(2);
            sample.start=ticd.getSampleFor(time.start);
            sample.end=ticd.getSampleFor(time.end);
            obj.voltageArray=obj.voltageArray(sample.start:sample.end);
            
        end

        function plot(obj,varargin)
            va=obj.getVoltageArray;
            t=obj.TimeIntervalCombined;
            t_s=t.getTimePointsInSec;
            diff1=numel(t_s)-numel(va);
            va((numel(va)+1):(numel(va)+diff1))=zeros(diff1,1);
            t_s=t.getStartTime+seconds(t_s);
            plot(t_s,va);
        end
    end
end

