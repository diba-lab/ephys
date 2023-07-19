classdef TimeFrequencyMapWavelet < neuro.tf.TimeFrequencyMap
    %TIMEFREQUENCYMAPWAVELET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = TimeFrequencyMapWavelet(...
                matrix, timePoints,frequencyPoints)
            %TIMEFREQUENCYMAPWAVELET Construct an instance of this class
            %   Detailed explanation goes here
            obj@neuro.tf.TimeFrequencyMap(matrix, timePoints,frequencyPoints)
%             obj.clim=[0 1];
        end
        
        function imsc = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mat=(abs(obj.matrix));
            imsc=imagesc(obj.timePoints-obj.timePoints(1),...
                obj.frequencyPoints,mat);
            ax=gca;
            ax.YDir='normal';
            ax.XLim=[0 max(obj.timePoints)];
            ax.YLim=[obj.frequencyPoints(1) obj.frequencyPoints(end)];
            m=mean2(mat);s=std2(mat);
            ax.CLim=[m-2*s m+2*s];
        end
        function phase = getPhase(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            va=angle(obj.matrix(ismember(obj.frequencyPoints,freq),:));
            phase=neuro.basic.Channel(num2str(freq),va,obj.timeIntervalCombined);
        end
        function power = getPower(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            va=abs(obj.matrix(ismember(obj.frequencyPoints,freq),:));
            if size(va,1)>1
                va=mean(va,1);
            end
            power=neuro.basic.Channel(num2str(freq),va,obj.timeIntervalCombined);
        end
    end
end

