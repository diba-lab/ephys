classdef (Abstract) BinarySave
    %BINARYSAVE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function [outputFile, status,cmdout]= keepChannels(obj, binaryFile, outputFile, nChannels, channels)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            tic
            
            [status,cmdout]=system([sprintf('process_extractchannels %s %s %d',...
                binaryFile,outputFile, nChannels) ...
                sprintf(' %d',channels-1)],'-echo');
            toc
        end
        function outputFile = excludeChannels(obj, binaryFile, outputFile, channels)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
        end
        function outputFile = mergeFiles(obj, outputFile, varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
        end
        function outputFile = excludeTimes(obj, binaryFile, outputFile, timesWindows)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
        end
        function outputFile = keepTimes(obj, binaryFile, outputFile, timesWindows)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
        end
    end
end

