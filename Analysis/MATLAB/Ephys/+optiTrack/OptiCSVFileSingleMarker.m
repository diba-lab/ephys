classdef OptiCSVFileSingleMarker<optiTrack.OptiCSVFile
    %OPTICSVFILESINGLEMARKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function newobj = OptiCSVFileSingleMarker(file)
            %OPTICSVFILESINGLEMARKER Construct an instance of this class
            %   Detailed explanation goes here
            newobj@optiTrack.OptiCSVFile(file);
            newobj= newobj.loadData(file);
        end
        
        function obj = loadData(obj,file)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% Single Marker
            if ~exist("file","var")
                file=obj.file;
            end
            opts = detectImportOptions(file,"ReadVariableNames",true,"ExpectedNumVariables",5,VariableNamesLine=7);
            opts.VariableNames = {'Frame', 'Time', 'X', 'Y', 'Z'};
            opts.VariableTypes={'uint32','double','double','double','double'};
            opts.DataLines=[8 inf];
            opts.ExtraColumnsRule = 'ignore';
            opts.EmptyLineRule = 'read';
            T=readtable(file,opts);
            obj.table = T;
        end
        function st=getStartTime(obj)
            st=obj.CaptureStartTime;
        end
        function sr=getSampleRate(obj)
            sr=obj.ExportFrameRate;
        end
        function nf=getNumFrames(obj)
            nf=obj.TotalExportedFrames;
        end

    end
end

