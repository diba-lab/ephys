classdef (Abstract) SpikeNeuroscope
    %SPIKENEUROSCOPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    methods (Abstract)
        getSpikeClusters
        getSpikeTimes
    end
    methods
        function [] = saveCluFile(obj, FileName)
            %SPIKENEUROSCOPE Construct an instance of this class
            %   Detailed explanation goes here
            spikeClusters=obj.getSpikeClusters;
            nClusters = numel(spikeClusters);
            
            outputfile = fopen(FileName,'w');
            fprintf(outputfile, '%d\n', nClusters);
            fprintf(outputfile,'%d\n', spikeClusters(:));
            fclose(outputfile);
        end
        
        function [] = saveResFile(obj,FileName)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputfile = fopen(FileName,'w');
            spikeTimes=obj.getSpikeTimes;
            
            fprintf(outputfile,'%d\n', spikeTimes(:));
            fclose(outputfile);
        end
    end
end

