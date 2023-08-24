classdef Manager
    %SESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        records
    end
    properties (Access=private)
        load
        cached
        conffile
    end
    methods (Access=private)
        function obj = Manager(conf)
            %SESSION Construct an instance of this class
            %   Detailed explanation goes here
            if exist(conf,"file")
                s=load(conf);
                tbl=s.tbl;
            else
                tbl = table('Size',[0 3],...
                    'VariableTypes',{'string','string','string'}, ...
                    'VariableNames',{'Key','File','FileExt'});
                [folder,file,ext]=fileparts(conf);
                if ~isfolder(folder)
                    mkdir(folder);
                end
                save(conf,'tbl');
            end
            keep=false(height(tbl),1);
            for it=1:height(tbl)
                ir=tbl.File(it);
                if isfile(ir)
                    keep(it)=1;
                end
            end
            obj.records=tbl(keep,:);
            obj.load=zeros([height(obj.records) 1]);
            obj.cached=CellArrayList;
            obj.conffile=conf;
            tbl=obj.records;
            save(conf,'tbl');
        end
    end
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance(conf)
            persistent uniqueInstance

            clear uniqueInstance;
            obj = cache.Manager(conf);
            uniqueInstance = obj;

        end
    end
    %*** Define your own methods for SingletonImpl.
    methods % Public Access
        function [obj]=reload(obj)
            % Find if exist in the table and update and return the key
            % or add it and return the generated key.
            obj=cache.Manager.instance(obj.conffile);
        end
        function [obj,key]=hold(obj, val,fileext)
            % Find if exist in the table and update and return the key
            % or add it and return the generated key.
            if exist('fileext','var')
                fn=strcat(class(val),'_', fileext);
            else
                fn=strcat(class(val), DataHash(val.toString));
            end
            tbl=obj.records;
            if ismember(fn,tbl.Key)
                % replace the saved file
                save(tbl.File(ismember(tbl.Key,fn)),'val');
                % if loaded replace the loaded item as well or add to
                % loaded
                if obj.load(ismember(tbl.Key,fn))>0
                    position=obj.load(ismember(tbl.Key,fn));
                    obj.cached.remove(position);
                    obj.cached.add(val,position);
                else
%                     obj.cached.add(val);
%                     obj.load(ismember(tbl.Key,fn))=obj.cached.length;
                end
                key=fn;
            else
                % save into file
                s1.Key=fn;
                if exist('fileext','var')
                    s1.FileExt=fileext;
                else
                    s1.FileExt=[];
                end
                s1.File=fullfile(obj.getFolder,strcat(fn,'.mat'));
                save(s1.File,'val');
                % add to table and save the table
                tbl=[tbl;struct2table(s1)];
                save(obj.conffile,"tbl");
                obj.records=tbl;
                % add it to loaded;
                obj.load=[obj.load;obj.cached.length];
                obj.cached.add(val);
                key=s1.Key;
            end
        end
        function val=get(obj, key)
            % search the key in the table, find if loaded if so return
            % else and load the variable from file and put it into record
            % and return
            tbl=obj.records;
            pos=ismember(tbl.Key,key)|ismember(tbl.FileExt,key);
            if any(pos)
                if obj.load(pos)>0
                    val=obj.cached.get(obj.load(pos));
                else
                    s=load(tbl.File(pos));
                    val=s.val;
                    obj.cached.add(val);
                    obj.load(pos)=obj.cached.length;
                end
            else
                val=[];
            end
         end
    end
    methods 
        function folder=getFolder(obj)
            [folder,~,~]=fileparts(obj.conffile);
        end
    end
end

