classdef TimeFrequencyWavelet < TimeFrequencyMethod
    %TIMEFREQUENCYPROPERTIESWAVELET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        centralFrequency
        scalingExponent
        sampleRate
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
                data, sampleRate)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            matrix=cmorTransSpec(data,...
                sampleRate,...
                obj.FrequencyInterest,...
                obj.centralFrequency,...
                obj.scalingExponent);
            l=logging.Logger.getLogger;
            l.info(sprintf('go'));
            aTimeFrequencyMap=TimeFrequencyMapWavelet(...
                matrix, (1:numel(data))/sampleRate, obj.FrequencyInterest);
        end
    end
end

