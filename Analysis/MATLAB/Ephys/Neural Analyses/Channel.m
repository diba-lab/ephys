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
            if numel(voltageArray)>timeIntervalCombined.getNumberOfPoints
                voltageArray=voltageArray(1:timeIntervalCombined.getNumberOfPoints);
            elseif numel(voltageArray)<timeIntervalCombined.getNumberOfPoints
                diff1=timeIntervalCombined.getNumberOfPoints-numel(voltageArray);
                voltageArray((numel(voltageArray)+1):timeIntervalCombined.getNumberOfPoints)...
                    =zeros(diff1,1);
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
                obj.sampleRate)
        end
        function chan=getChannelName(obj)
            chan=obj.ChannelName;
        end
        function st=getTimeIntervalCombined(obj)
            st=obj.TimeIntervalCombined;
        end
        
        function obj=getTimeWindowForAbsoluteTime(obj,window)
            window1=datetime(window,'Format','HH:mm');
            ticd=obj.TimeIntervalCombined;
            [h,m,s]=hms(ticd.getStartTime);
            basetime=ticd.getStartTime-hours(h)-minutes(m)-seconds(s);
            time.start=basetime+hours(window1(1).Hour)+minutes(window1(1).Minute);
            time.end=basetime+hours(window1(2).Hour)+minutes(window1(2).Minute);
            sample.start=ticd.getSampleFor(time.start);
            sample.end=ticd.getSampleFor(time.end);
            ticd1=ticd.getTimeIntervalForTimes(time.start,time.end);
            obj.voltageArray=obj.voltageArray(sample.start:sample.end);
            obj.TimeIntervalCombined=ticd1;
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

