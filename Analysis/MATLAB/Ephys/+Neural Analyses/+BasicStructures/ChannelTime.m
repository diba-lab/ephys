classdef ChannelTime
    %CHANNELTIME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Data
        Channels
        Time
        Info
    end
    
    methods
        function obj = ChannelTime(data,ch,time)
            %CHANNELTIME Construct an instance of this class
            %   Detailed explanation goes here
            obj.Data = data;
            obj.Channels= ch;
            obj.Time=time;
        end
        
        function obj = getWindow(obj,window)
            t=obj.Time;
            if isduration(window)
                timepoint=t(end);
                window=window+datetime(year(timepoint),month(timepoint),day(timepoint));
            end
            time_idx=(t>window(1)&t<window(2));
            obj.Time=t(time_idx);
            obj.Data=obj.Data(:,time_idx);           
        end
    end
end

