classdef (Abstract) SpikeNeuroscope
    %SPIKENEUROSCOPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function [] = saveCluFile(obj, FileName,spikeClusters)
            %SPIKENEUROSCOPE Construct an instance of this class
            %   Detailed explanation goes here
            
            nClusters = numel(spikeClusters);
            
            outputfile = fopen(FileName,'w');
            fprintf(outputfile, '%d\n', nClusters);
            fprintf(outputfile,'%d\n', spikeClusters(:));
            fclose(outputfile);
        end
        
        function [] = saveResFile(obj,FileName,spikeTimes)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputfile = fopen(FileName,'w');
            fprintf(outputfile,'%d\n', spikeTimes(:));
            fclose(outputfile);
        end
    end
end

