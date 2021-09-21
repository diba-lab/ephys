classdef OptiFBXAsciiFile<optiTrack.OptiFile
    %OPTITAKFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TakeName
        ExportFrameRate
        CaptureStartTime
        TotalExportedFrames
        startLine
    end    
    methods
        function obj = OptiFBXAsciiFile(file)
            %OPTITAKFILE Construct an instance of this class
            %   Detailed explanation goes here
            obj.file=file;
            
            %%Header
            obj=obj.loadHeader(file);
            obj=obj.loadData(file);
        end
        
        function [obj] = loadHeader(obj,file)
            %% Header
            opts = delimitedTextImportOptions("NumVariables", 7);

            % Specify range and delimiter
            opts.DataLines = [1, 1000];
            opts.Delimiter = [",", ":"];
            
            % Specify column names and types
            opts.VariableNames = ["v1", "v2", "v3", "v4", "v5", "v6", "v7"];
            opts.VariableTypes = ["char", "char", "double", "double", "char", "char", "char"];
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = 'read';
            vars = readtable(file, opts);
            [~,locb]=ismember('RawSegs',vars.v1);
            obj.startLine=locb+2;
            obj.TotalExportedFrames=vars.v4(obj.startLine-1);
            [~,locb]=ismember('Take',vars.v1);
            obj.TakeName=vars.v2{locb};
            obj.TakeName=obj.TakeName(1:end-2);
            
            postheaderline=obj.startLine+obj.TotalExportedFrames;
            opts.DataLines = [postheaderline, inf];
            vars = readtable(file, opts);
            opts.VariableTypes = ["char", "double", "double", "double", "char", "char", "char"];
            [~,locb]=ismember('FrameRate',vars.v1);
            obj.ExportFrameRate=vars.v2(locb);
            obj.ExportFrameRate=str2double(obj.ExportFrameRate{1});
            
            obj.CaptureStartTime=datetime(...
                obj.TakeName(6:27),'InputFormat','yyyy-MM-dd hh.mm.ss a');  
            
%             opts.SelectedVariableNames = ["v2", "v3", "v4"];
%             opts.DataLines = [490, 490+obj.TotalExportedFrames-1];
%             obj.table=readtable(file, opts);
        end
        function [ts1] = getTimeSeriesX(obj)
            ts1=timeseries(obj.table.X,obj.getTime());
            ts1.Name='X Data';
            ts1.TimeInfo.Units='seconds';
            ts1.TimeInfo.StartDate=obj.CaptureStartTime;
        end
        function [ts1] = getTimeSeriesY(obj)
            ts1=timeseries(obj.table.Y,obj.getTime());
            ts1.Name='Y Data';
            ts1.TimeInfo.Units='seconds';
            ts1.TimeInfo.StartDate=obj.CaptureStartTime;
        end
        function [ts1] = getTimeSeriesZ(obj)
            ts1=timeseries(obj.table.Z,obj.getTime());
            ts1.Name='Z Data';
            ts1.TimeInfo.Units='seconds';
            ts1.TimeInfo.StartDate=obj.CaptureStartTime;
        end
        function time=getTime(obj)
            time=linspace(0,obj.TotalExportedFrames/obj.ExportFrameRate,obj.TotalExportedFrames);
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

        function obj = loadData(obj,file)
                %% Header
                adjustmentRatio=4;
            opts = delimitedTextImportOptions("NumVariables", 7);
            % Specify column names and types
            opts.VariableNames = ["v1", "X", "Y", "Z", "v5", "v6", "v7"];
            opts.SelectedVariableNames=["X","Y","Z"];
            opts.VariableTypes = ["char", "double", "double", "double", "char", "char", "char"];
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            
            opts.Delimiter = [",", ":"];
            
            opts.DataLines = [obj.startLine, obj.startLine+obj.TotalExportedFrames-1];
            obj.table=readtable(file, opts);
            obj.table.X=obj.table.X/adjustmentRatio;
            obj.table.Y=obj.table.Y/adjustmentRatio;
            obj.table.Z=obj.table.Z/adjustmentRatio;
        end

    end
end