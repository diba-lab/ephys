classdef (Abstract) OptiCSVFile <optiTrack.OptiFile
    %OPTITAKFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FormatVersion
        TakeNotes
        TakeName
        CaptureFrameRate
        ExportFrameRate
        CaptureStartTime
        TotalFramesinTake
        TotalExportedFrames
        RotationType
        LengthUnits
        CoordinateSpace
    end
    
    methods (Abstract)
        loadData(obj)
    end
    
    methods
        function obj = OptiCSVFile(file)
            %OPTITAKFILE Construct an instance of this class
            %   Detailed explanation goes here
            obj.file=file;
            
            %%Header
            obj=obj.loadHeader(file);
        end
        
        function [obj] = loadHeader(obj, file)
            %% Header
            opts = delimitedTextImportOptions("NumVariables", 22);

            % Specify range and delimiter
            opts.DataLines = [1, 1];
            opts.Delimiter = ",";
            
            % Specify column names and types
            opts.VariableNames = ["a1", "FormatVersion", "a2", "TakeName", "a3", "TakeNotes", "a4",...
                "CaptureFrameRate", "a5", "ExportFrameRate", "a6", "CaptureStartTime",...
                "a7", "TotalFramesinTake", "a8", "TotalExportedFrames",...
                "a9", "RotationType", "a10", "LengthUnits", "a11", "CoordinateSpace"];
            opts.VariableTypes = ["char", "char", "char", "char", "char", "char", "char", "double",...
                "char", "double", "char", "char", "char", "double", "char", "double",...
                "char", "char", "char", "char", "char", "char"];
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            vars = readtable(file, opts);
            obj.TakeName=vars.TakeName;
            obj.FormatVersion=vars.FormatVersion;
            obj.TakeNotes=vars.TakeNotes;
            obj.TakeName=vars.TakeName;
            obj.CaptureFrameRate=vars.CaptureFrameRate;
            obj.ExportFrameRate=vars.ExportFrameRate;
            obj.CaptureStartTime=datetime(vars.CaptureStartTime,'InputFormat','yyyy-MM-dd hh.mm.ss.SSS a');
            obj.TotalFramesinTake=vars.TotalFramesinTake;
            obj.TotalExportedFrames=vars.TotalExportedFrames;
            obj.RotationType=vars.RotationType;
            obj.LengthUnits=vars.LengthUnits;
            obj.CoordinateSpace=vars.CoordinateSpace;
                        
        end
        function [ts1] = getTimeSeriesX(obj)
            ts1=timeseries(obj.table.X,obj.getTime);
            ts1.Name='X Data';
            ts1.TimeInfo.Units='seconds';
            ts1.TimeInfo.StartDate=obj.CaptureStartTime;
        end
        function [ts1] = getTimeSeriesY(obj)
            ts1=timeseries(obj.table.Y,obj.getTime);
            ts1.Name='Y Data';
            ts1.TimeInfo.Units='seconds';
            ts1.TimeInfo.StartDate=obj.CaptureStartTime;
        end
        function [ts1] = getTimeSeriesZ(obj)
            ts1=timeseries(obj.table.Z,obj.getTime);
            ts1.Name='Z Data';
            ts1.TimeInfo.Units='seconds';
            ts1.TimeInfo.StartDate=obj.CaptureStartTime;
        end
        function time=getTime(obj)
            time=obj.table.Time;
        end

    end
end