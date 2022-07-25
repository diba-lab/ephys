classdef (Abstract) BinarySave
    %BINARYSAVE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function [outputFile, status, cmdout]= keepChannels(obj, binaryFile, outputFile, nChannels, channels)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            tic
            
            [status,cmdout]=system([sprintf('process_extractchannels "%s" "%s" %d',...
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
        function [ctd1]= saveKeepTimes(obj, timesWindows)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %%  FROM Buzcode buzcode/preprocessing/intanToolbox/CutDatFragment
%             amplifier.dat
            disp('Writing amplifier file')
            pr=obj.getProbe;
            ticd=obj.getTimeIntervalCombined;
            if ~isnumeric(timesWindows)
                samples=ticd.getSampleFor(timesWindows);
            else
                samples=timesWindows;
            end
            ticdnew=ticd.getTimeIntervalForTimes(timesWindows);
            chans=pr.getActiveChannels;
            NumCh = length(chans);
            inname=obj.getFilepath;
            [folder,name,ext]=fileparts(inname);
            hash=DataHash(timesWindows);
            newfolder=fullfile(folder,strcat('fragment_',hash),name);
            if ~isfolder(newfolder), mkdir(newfolder);end
            outname =fullfile(newfolder,strcat(name,ext));
            chunksize=1e8;
            chunklength=chunksize/NumCh/2;
            file=dir(inname);
            samplesx=file.bytes/2/NumCh;
            a = memmapfile(inname,'Format',{'int16',[NumCh samplesx],'data'});
            fid = fopen(outname,'w');
            for i=1:size(samples,1)
                time=samples(i,:);
                for ichunk=time(1):chunklength:time(2)
                    chunkst=ichunk;
                    chunkend=chunkst+chunksize-1;
                    if chunkend>time(2), chunkend=time(2);end
                    chunk=a.Data.data(:,chunkst:chunkend);
                    fwrite(fid,chunk,'int16');
                end
            end
            fclose(fid);
            clear a
            ctd1=obj;
            ctd1=ctd1.setTimeIntervalCombined(tic,dnew);
            ctd1=ctd1.setProbe(pr);
            ctd1=ctd1.setFile(outname);
            ctd1.save

        end
    end
end

