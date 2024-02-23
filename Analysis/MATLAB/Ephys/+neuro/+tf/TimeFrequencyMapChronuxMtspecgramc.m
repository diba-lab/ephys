classdef TimeFrequencyMapChronuxMtspecgramc < neuro.tf.TimeFrequencyMap
    %TIMEFREQUENCYMAPSPECTROGRAM Summary of this class goes here
    %   Detailed explanation goes here
    properties
    end
    methods
        function obj = TimeFrequencyMapChronuxMtspecgramc(...
                matrix, timePoints, frequencyPoints)
            %TIMEFREQUENCYMAPSPECTROGRAM Construct an instance of this class
            %   Detailed explanation goes here
            obj@neuro.tf.TimeFrequencyMap(matrix, timePoints, frequencyPoints);
        end
        function imsc = plot(obj,ax,clim)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes her  e
            if ~exist('ax','var')||isempty('ax')
                ax=gca;
            end
            mat=(abs(obj.matrix));
            imsc=imagesc(ax,seconds(obj.timePoints),...
                obj.frequencyPoints,mat);
            if ~exist('clim','var')||isempty('clim')
            else
                ax.CLim=clim;
            end
            ax.XLabel.String='Time (s)';
            ax.YLabel.String='Frequency Hz';
            %             colormap('copper');
            %             cb=colorbar;
            %             cb.Label.String='Amplitude (dB)';
            ax.YDir='normal';
            m=mean2(mat);s=std2(mat);
            ax.CLim=[m-2*s m+2*s];
        end
    end
    methods (Access=public)
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
            new=neuro.tf.TimeFrequencyMapChronuxMtspecgramc(newmat,tps_gen,obj.frequencyPoints);
        end
    end
end

