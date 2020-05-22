classdef TimeFrequencyWavelet < TimeFrequencyMethod
    %TIMEFREQUENCYPROPERTIESWAVELET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        centralFrequency
        scalingExponent
    end
    
    methods
        function obj = TimeFrequencyWavelet(frequencyInterests,...
                centralFrequency, scalingExponent)
            %TIMEFREQUENCYPROPERTIESWAVELET Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@TimeFrequencyMethod(frequencyInterests);
            if nargin>2
                obj.scalingExponent = scalingExponent;
            else
                obj.scalingExponent=-1/2;
            end
            if nargin>1
                obj.centralFrequency = centralFrequency;
            else
                obj.centralFrequency = 1;
            end
        end
        
        function aTimeFrequencyMap = execute(obj,...
                data, time)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            matrix=cmorTransSpec(data,...
                obj.getSamplingFrequency(time),...
                obj.FrequencyInterest,...
                obj.centralFrequency,...
                obj.scalingExponent);
            aTimeFrequencyMap=TimeFrequencyMapWavelet(...
                matrix, time, obj.FrequencyInterest);
        end
    end
end

