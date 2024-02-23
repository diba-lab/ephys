classdef NeuroscopeEvents < neuro.event.Events
    %NEUROSCOPEEVENTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = NeuroscopeEvents(filepath)
            %NEUROSCOPEEVENTS Construct an instance of this class
            %   Detailed explanation goes here
            if isstring(filepath)||ischar(filepath)
                t=readtable(filepath,'FileType', 'text');
                Time=t.Var1/1000;
                t2=t.Var2;
                t1=table(Time,t2,'VariableNames',{'Time','Type'});
                obj.timetable=t1;
                obj.info.path=filepath;
            end
        end
        
        function tt = getTableTypesInColumn(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t=obj.timetable;
            vars=t.Properties.VariableNames;
            types=t.(vars{2});
            times=t.Time;
            typesunique=unique(types);
            for it=1:numel(typesunique)
                type=typesunique{it};
                typeidx=ismember(types,type);
                time{it}=times(typeidx);
                type(1)=upper(type(1));
                typesunique{it}=type;
            end
            tt=table(time{:},'VariableNames',typesunique);
        end
        function file=saveCSVtable(obj,filename)
            t=obj.getTableTypesInColumn;
            [folder,filename1,~]=fileparts(obj.info.path);
            ext='.csv';
            if ~exist('filename','var')||isempty(filename)
                file=fullfile(folder,[filename1 ext]);
            else
                file=fullfile(folder,[filename ext]);
            end
            writetable(t,file)
        end
        function file=plus(obj,events)
            
        end
        function file=saveSpykingCircusDeadFile(obj)
            t=obj.getTableTypesInColumn;
            tw=time.TimeWindowsDuration(t);
            [folder,~,~]=fileparts(obj.info.path);
            file=tw.saveForClusteringSpyKingCircus(folder);
        end
        function file=saveEVT(obj,filename)
            t=obj.getTableTypesInColumn;
            [folder,filename1,~]=fileparts(obj.info.path);
            ext='.evt';
            if ~exist('filename','var')||isempty(filename)
                file=fullfile(folder,[filename1 ext]);
            else
                file=fullfile(folder,[filename ext]);
            end
            writetable(t,file)
        end
    end
end

