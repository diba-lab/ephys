classdef TimeFrequencyMapSpectrogram < TimeFrequencyMap
    %TIMEFREQUENCYMAPSPECTROGRAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = TimeFrequencyMapSpectrogram(...
                matrix, timePoints, frequencyPoints)
            %TIMEFREQUENCYMAPSPECTROGRAM Construct an instance of this class
            %   Detailed explanation goes here
            obj@TimeFrequencyMap(matrix, timePoints, frequencyPoints);
            obj.clim=[0 20000];
        end
        
        function imsc = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            imsc=imagesc(obj.timePoints,...
                obj.frequencyPoints,abs(obj.matrix),obj.clim);
            
        end
    end
end

