classdef ChannelProcessed < neuro.basic.Channel
    %CHANNELPROCESSED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        parent
        processingInfo
    end
    
    methods
        function obj = ChannelProcessed(obj1)
            %CHANNELPROCESSED Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                fnames=fieldnames(obj1);
                for ip=1:numel(fnames)
                    obj.(fnames{ip})=obj1.(fnames{ip});
                end
            end
        end
        function obj=getTimeWindow(obj,window)
            obj=getTimeWindow@neuro.basic.Channel(obj,window);
            if ~isempty(obj.parent)
                obj.parent=obj.parent.getTimeWindow(window);
            end
        end

    end
end

