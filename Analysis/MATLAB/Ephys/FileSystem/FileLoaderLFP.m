classdef FileLoaderLFP < FileLoaderMethod
    %FILELOADERBINARY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        LFPFile
        TimestampsandHeaderFile
    end
    
    methods
        function obj = FileLoaderLFP(LFPFile)
            %FILELOADERBINARY Construct an instance of this class
            %   Detailed explanation goes here
            obj.LFPFile=LFPFile;
            [filepath,name,ext]=fileparts(LFPFile);
            listing=dir([filepath filesep name '.header*.mat']);
            obj.TimestampsandHeaderFile=fullfile(listing.folder,listing.name);
        end
      
        function openEphysRecord = load(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            S = load(obj.TimestampsandHeaderFile);
            numberOfChannels=numel(S.header.getChannels);
            file=dir(obj.LFPFile);
            samples=file.bytes/2/numberOfChannels;
            Data=memmapfile(obj.LFPFile,'Format',{'int16' [numberOfChannels samples] 'mapped'});
            
            
            openEphysRecord.Header=S.header;
            openEphysRecord.Timestamps=S.timestamps;
            openEphysRecord.Data=Data;
        end
    end
end
