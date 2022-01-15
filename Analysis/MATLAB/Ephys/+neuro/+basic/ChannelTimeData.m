classdef ChannelTimeData
    %CHANNELTIMEDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Channels
        Time
        Data
    end
    
    methods
        function obj = ChannelTimeData(ch, time, data)
            %CHANNELTIMEDATA Construct an instance of this class
            %   Detailed explanation goes here
            l= logging.Logger.getLogger;
            if isa(ch,'neuro.probe.Probe')
                obj.Channels = ch;
            else
                l.error('Provide neuro.probe.Probe object.')
            end
            if isa(time,'neuro.time.TimeIntervalCombined')
                obj.Time = time;
            else
                l.error('Provide neuro.time.TimeIntervalCombined object.')
            end
            if isequal(size(data),[numel(ch.getActiveChannels) time.getNumberOfPoints])
                obj.Data=data;
            else
                l.error('Data size is not compatible with channel and time info.')
            end
        end
        
        function obj = get(obj,channels,time)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~exist('channels','var')|| isempty(channels)
                channels=obj.Channels.getActiveChannels;
            end
            if ~exist('time','var')|| isempty(time)
                time=[obj.Time.getStartTime obj.Time.getEndTime];
            end
        end
    end
end

