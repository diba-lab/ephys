classdef OptiCSVFileGeneral < position.optiTrack.OptiCSVFile
    %OPTICSVFILEGENERAL Summary of this class goes here
    %   Detailed explanation goes here

    properties
        TableDefinition
        Positions
    end

    methods
        function obj = OptiCSVFileGeneral(file)
            %OPTICSVFILEGENERAL Construct an instance of this class
            %   Detailed explanation goes here
            obj@position.optiTrack.OptiCSVFile(file);
            obj= obj.loadData(file);
        end

        function obj = loadData(obj,file)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% Single Marker
            if ~exist("file","var")
                file=obj.file;
            end
            opts=detectImportOptions(file,"ReadVariableNames",false);
            for i=1:numel(opts.VariableTypes)
                opts.VariableTypes{i}='char';
            end
            opts.DataLines=[3 7];
            t=readtable(file,opts);
            celt=table2cell(t)';
            tbl1=cell2table(celt(3:end,:),VariableNames= ...
                [celt(2,1:3),"RotPos","XYZ"]);
            tbl2=tbl1(ismember(tbl1.RotPos,'Position'),:);
            opts=[];
            opts = detectImportOptions(file);

            % Specify range and delimiter
            opts.DataLines = [8, Inf];
            opts.Delimiter = ',';
            for iv=1:numel(opts.VariableTypes)
                opts.VariableTypes{iv}='double';
            end
            % Specify column names and types
            %             opts.VariableNames = {'Frame', 'Time', 'Xr', 'Yr', 'Zr', 'Wr', 'X', 'Y', 'Z'};
            %             opts.VariableTypes = {'uint32', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'};
            %             opts.EmptyLineRule = 'read';
            T=readtable(file,opts);
            obj.table = T;
            T1=T(:,3:end);
            list=unique(tbl2(:,1:4));

            prompt = {'Zeitgeber Time:'};
            dlgtitle = datestr(obj.CaptureStartTime);
            dims = [1 10];
            definput = {'08:00'};
            zt = duration(inputdlg(prompt,dlgtitle,dims,definput),'InputFormat','hh:mm');


            ticzt=time.TimeIntervalZT(obj.CaptureStartTime, ...
                obj.ExportFrameRate,obj.TotalExportedFrames,zt);
            for ipos=1:height(list)
                ln=list(ipos,:);
                idx=ismember(tbl1.Type,ln.Type)&...
                    ismember(tbl1.Name,ln.Name)&...
                    ismember(tbl1.RotPos,ln.RotPos)&...
                    ismember(tbl1.ID,ln.ID);
                varnames=tbl1(idx,'XYZ');
                mes=T1(:,idx);
                mes.Properties.VariableNames=table2cell(varnames)';

                pds{ipos,1}=position.PositionData(mes.X',mes.Y',mes.Z',ticzt);
            end
            list.PositionData=pds;
            obj.Positions=list;
            obj.TableDefinition=tbl1;
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
%         function positionData=getMergedPositionData(obj)
%             poss=obj.Positions;
%         end
    end
end

