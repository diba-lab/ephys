classdef ChannelTimeDataHardBad < neuro.basic.ChannelTimeDataHard
    %CHANNELTIMEDATAHARDBAD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Bad
    end
    
    methods
        function obj = ChannelTimeDataHardBad(filepath,Bad)
            %CHANNELTIMEDATAHARDBAD Construct an instance of this class
            %   Detailed explanation goes here
            obj@neuro.basic.ChannelTimeDataHard(filepath)
            obj.Bad=Bad;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

