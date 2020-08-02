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
            obj.clim=[0 3.7];
            obj.clim=[0 2];
        end
        
        function imsc = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes her  e
            adj=obj.getTimePointsAdjusted;
            
            imsc=imagesc(seconds(adj.timePoints-adj.timePoints(1)),...
                adj.frequencyPoints,log10( abs(adj.matrix')),adj.clim);
            colormap('copper');
        end
    end
    methods (Access=private)
        function new=getTimePointsAdjusted(obj)
            sampleRate=mode(seconds(diff(obj.timePoints)));
            tps=obj.timePoints;
            st=tps(1);
            tps1=seconds(tps-tps(1));
            tps_gen=tps1(1):sampleRate:tps1(end);
            tps_gen=seconds(tps_gen)+st;
            mat=obj.matrix;
            newmat=nan(size(mat));
            itp=1;
            for tp=tps_gen
                [minValue,closestIndex]=min(abs(tps-tp));
                if seconds(minValue)<1
                    newmat(itp,:) = mat(closestIndex,:);
                else
                    
                end
                itp=itp+1;
            end
            new=TimeFrequencyMapChronuxMtspecgramc(newmat,tps_gen,obj.frequencyPoints);
        end
    end
end

