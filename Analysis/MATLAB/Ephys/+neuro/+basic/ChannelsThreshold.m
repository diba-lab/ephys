classdef ChannelsThreshold < neuro.basic.Channel
    %CHANNELSTHRESHOLD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Threshold
        Sticky
    end
    
    methods
        function obj = ChannelsThreshold(channel,threshold,sticky)
            %CHANNELSTHRESHOLD Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@neuro.basic.Channel(channel.getChannelName,channel.getValues,channel.getTimeInterval);
            obj.Threshold=threshold;
            obj.Info=channel.Info;
            try
                obj.Sticky=sticky;
            catch
                obj.Sticky=false;
            end
        end
        
        function thr = getThreshold(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            thr=obj.Threshold;
        end
        function obj = setThreshold(obj,thr)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Threshold=thr;
        end
        function obj = setThresholdSticky(obj,sticky)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Sticky=sticky;
        end
        function thr = isThreshold(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            thr=obj.Threshold;
        end
    end
end

