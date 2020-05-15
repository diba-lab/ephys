classdef TimeFrequencyMethod
    %TIMEFREQUENCYMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FrequencyInterest
    end
    
    methods(Abstract)
        execute(obj,data,frequency,time)
    end
    
    
    methods
        function obj = TimeFrequencyMethod(frequencyInterest)
            %TIMEFREQUENCYMETHOD Construct an instance of this class
            %   Detailed explanation goes here
            obj.FrequencyInterest = frequencyInterest;
        end
        
        function samplingRate = getSamplingFrequency(obj,time)
            %TIMEFREQUENCYMETHOD Construct an instance of this class
            %   Detailed explanation goes here
            if isdatetime(time)
                period=unique(diff(second(time)));
            else
                period=unique(diff(time));
            end
            samplingRate = round(max(1./period));
        end
        
    end
end