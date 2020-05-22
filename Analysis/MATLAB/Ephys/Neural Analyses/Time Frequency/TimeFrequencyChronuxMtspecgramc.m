classdef TimeFrequencyChronuxMtspecgramc < TimeFrequencyMethod
    %TIMEFREQUENCYPROPERTIESWAVELET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        movingWindow
        tapers
        pad
        Fs
        fpass
        err
    end
    
    methods
        function obj = TimeFrequencyChronuxMtspecgramc(frequencyInterests,...
                tapers, pad, err)
            %TIMEFREQUENCYPROPERTIESWAVELET Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@TimeFrequencyMethod(frequencyInterests);
            obj.fpass=frequencyInterests;
            obj.movingWindow=[1250 1250/2]/1000;
            if nargin>3
                obj.tapers = tapers;
            else
            end
            if nargin>2
                obj.pad = pad;
            else
            end
            if nargin>1
                obj.err = err;
            else
            end
        end
        
        function aTimeFrequencyMap = execute(obj,...
                data, time)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            movingwin=obj.movingWindow;
            params.fpass=[obj.FrequencyInterest(1) obj.FrequencyInterest(end)];
            params.Fs=obj.getSamplingFrequency(time);
            [matrix,t,f]=mtspecgramc(data,movingwin,params);
            aTimeFrequencyMap=TimeFrequencyMapChronuxMtspecgramc(...
                matrix, seconds(t)+time(1), f);
        end
    end
end

