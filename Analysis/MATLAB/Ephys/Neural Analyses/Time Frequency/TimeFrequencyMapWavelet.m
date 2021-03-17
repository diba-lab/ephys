classdef TimeFrequencyMapWavelet < TimeFrequencyMap
    %TIMEFREQUENCYMAPWAVELET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = TimeFrequencyMapWavelet(...
                matrix, timePoints,frequencyPoints)
            %TIMEFREQUENCYMAPWAVELET Construct an instance of this class
            %   Detailed explanation goes here
            obj@TimeFrequencyMap(matrix, timePoints,frequencyPoints)
%             obj.clim=[0 1];
        end
        
        function imsc = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mat=abs(obj.matrix);
            imsc=imagesc(obj.timePoints-obj.timePoints(1),...
                obj.frequencyPoints,mat);
            ax=gca;
            ax.YScale='log';
            tickpoints=round(linspace(1,numel(obj.frequencyPoints),10));
            ax.YTick=unique(round(obj.frequencyPoints(tickpoints)));
            ax.YDir='normal';
            ax.XLim=[0 max(obj.timePoints-obj.timePoints(1))];
            min(min(mat))
            ax.YLim=[obj.frequencyPoints(1) obj.frequencyPoints(end)];
            ax.CLim=[1 250];
        end
        function phase = getPhase(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            va=angle(obj.matrix(ismember(obj.frequencyPoints,freq),:));
            phase=Channel(num2str(freq),va,obj.timeIntervalCombined);
        end
        function power = getPower(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            va=abs(obj.matrix(ismember(obj.frequencyPoints,freq),:));
            power=Channel(num2str(freq),va,obj.timeIntervalCombined);
        end
    end
end

