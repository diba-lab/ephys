classdef TimeFrequencySpectrogram < TimeFrequencyMethod
    %TIMEFREQUENCYPROPERTIESWAVELET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        window
        noverlap
        nfft
    end
    
    methods
        function obj = TimeFrequencySpectrogram(frequencyInterests,...
                window, noverlap, nfft)
            %TIMEFREQUENCYPROPERTIESWAVELET Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@TimeFrequencyMethod(frequencyInterests);
            ms=1000;
            if nargin>3
                obj.nfft = nfft;
            else
                obj.nfft=ms*1250/1000;
            end
            if nargin>2
                obj.noverlap = noverlap;
            else
                obj.noverlap=.8*ms*1250/1000;
            end
            if nargin>1
                obj.window = window;
            else
                obj.window = ms*1250/1000;
            end
        end
        
        function aTimeFrequencyMap = execute(obj,...
                data, time)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            [matrix, f, t] = spectrogram(data,...
                obj.window,...
                obj.noverlap,...
                obj.nfft,...
                obj.getSamplingFrequency(time));        
            aTimeFrequencyMap=TimeFrequencyMapSpectrogram(...
                matrix, seconds(t)+time(1), f);
            
            
        end
    end
end

