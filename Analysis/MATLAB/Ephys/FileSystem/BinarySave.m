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
            %%  FROM Buzcode buzcode/preprocessing/intanToolbox/CutDatFragment
%             amplifier.dat
%             disp('Writing amplifier file')
%             NumCh = length(amplifier_channels);
%             SampRate = frequency_parameters.amplifier_sample_rate;
%             if RenameOriginalsAsOrig
%                 inname = [fname '.dat_orig'];
%                 outname = [fname '.dat'];
%                 movefile(outname,inname)
%             else
%                 inname = [fname '.dat'];
%                 outname = [fname '_fragment.dat'];
%             end
%             a = memmapfile(inname,'Format','int16');
%             aa = a.data;
%             fid = fopen(outname,'W');
%             for i = timeperiod(1)+1:timeperiod(2)
%                 fwrite(fid,aa((i-1)*NumCh*SampRate+1:i*NumCh*SampRate),'int16');
%             end
%             fclose(fid);
%             clear aa a
        end
    end
end

