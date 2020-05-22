classdef StateChannel < Channel
    %SLEELPCHANNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        StateDetectionMethod
    end
    
    methods
        function obj = StateChannel(channel)
            %SLEELPCHANNEL Construct an instance of this class
            %   Detailed explanation goes here
            obj@Channel(channel.getChannelName,...
                channel.getTime,channel.getVoltageArray,channel.getStartTime);
            obj.StateDetectionMethod=StateDetectionBuzcode();
        end
        
        function results = runStateDetection(obj)
            theStateDetectionMethod=obj.StateDetectionMethod;
            results=theStateDetectionMethod.runStateDetection();
        end
    end
    %% Getter Setters
    methods
        
        function obj = setStateDetectionMethod(obj,aStateDetectionMethod)
            obj.StateDetectionMethod=aStateDetectionMethod;
        end
        function theStateDetectionMethod = getStateDetectionMethod(obj)
            theStateDetectionMethod=obj.StateDetectionMethod;
        end        
    end
end

