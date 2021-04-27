classdef OptiCSVFileSingleMarker<OptiCSVFile
    %OPTICSVFILESINGLEMARKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function newobj = OptiCSVFileSingleMarker(file)
            %OPTICSVFILESINGLEMARKER Construct an instance of this class
            %   Detailed explanation goes here
            newobj@OptiCSVFile(file);
            newobj= newobj.loadData(file);
        end
        
        function obj = loadData(obj,file)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% Single Marker
            
            fid = fopen(file);
            for i=1:8
                line_ex = fgetl(fid);  % read line excluding newline character
            end
            T=table('Size',[obj.TotalExportedFrames 5],'VariableTypes',{'uint32','double','double','double','double'},...
                'VariableNames',{'Frame','Time','X','Y','Z'});
            for i=1:(obj.TotalExportedFrames)
                line_ex = fgetl(fid);
                cols=strsplit(line_ex,',');
                T.Frame(i)=uint32(str2double(cols{1}));
                T.('Time')(i)=str2double(cols{2});
                try
                    T.X(i)=str2double(cols{3});
                    T.Y(i)=str2double(cols{4});
                    T.Z(i)=str2double(cols{5});
                catch
                    T.X(i)=nan;
                    T.Y(i)=nan;
                    T.Z(i)=nan;
                end
                if(mod(i,1000)==0)
                    fprintf('done: %d/%d\n',i,obj.TotalExportedFrames);
                end
            end
            fclose(fid);
            obj.table = T;
        end
    end
end

