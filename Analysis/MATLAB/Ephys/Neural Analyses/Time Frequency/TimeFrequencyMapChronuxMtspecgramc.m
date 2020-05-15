classdef TimeFrequencyMapChronuxMtspecgramc < TimeFrequencyMap
    %TIMEFREQUENCYMAPSPECTROGRAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = TimeFrequencyMapChronuxMtspecgramc(...
                matrix, timePoints, frequencyPoints)
            %TIMEFREQUENCYMAPSPECTROGRAM Construct an instance of this class
            %   Detailed explanation goes here
            obj@TimeFrequencyMap(matrix, timePoints, frequencyPoints);
            obj.clim=[0 1.5];
%             obj.clim=[0 6];
        end
        
        function imsc = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            imsc=imagesc(seconds(obj.timePoints-obj.timePoints(1)),...
                obj.frequencyPoints,log10( abs(obj.matrix')),obj.clim);
            obj.addTimeAxis()
            
        end
    end
end

