classdef RawEphys
    %RAWEPHYS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channelTime
        time
        samplingRate
        channels
    end
    
    methods
        function obj = RawEphys(inputArg1,inputArg2)
            %RAWEPHYS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

