classdef OptiLoader<Singleton
    %OPTILOADER Summary of this class goes here
    %   Detailed explanation goes here

    properties(Access=public)
        parameters
        defpath
    end

    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function newObj = OptiLoader(path)
            % Initialise your custom properties.
            s=xml2struct('+optiTrack/configuration.xml');
            fname=fieldnames(s);
            newObj.parameters=s.(fname{1});
            if exist('path','var')
                newObj.defpath=path;
            end
        end
    end

    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance(path)
            persistent uniqueInstance
            if isempty(uniqueInstance)||nargin>0
                if nargin>0
                    obj = optiTrack.OptiLoader(path);
                else
                    obj = optiTrack.OptiLoader();
                end
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end

    %*** Define your own methods for SingletonImpl.
    methods % Public Access
        function obj=reload(obj)
            Vars=whos;
            PersistentVars=Vars([Vars.global]);
            PersistentVarNames={PersistentVars.name};
            clear(PersistentVarNames{:});
        end
        function files=getOptiFilesCombined(obj)
            files= obj.OptifilesCombined;
        end
        %         function saveFiles(obj)
        %             files= obj.Files;
        %             for ifile=1:numel(files)
        %                 aFile=files{ifile};
        %                 [filepath,name,~]=fileparts(aFile.file);
        %                 save(fullfile(filepath,[name '.mat']),'aFile');
        %             end
        %         end
    end
    methods 
        function [pd] = loadFile(obj, files)
            % Just assign the input value to singletonData.  See Singleton
            % superclass.
            if(nargin<2)
                try
                    [files, path] = uigetfile({'*.csv;*.fbx','Exported Optitrack Files (*.csv,*.fbx)'},...
                        'Select the folder containing *.csv or *.fbx files.',...
                        obj.defpath,'MultiSelect', 'on');
                catch
                    [files, path] = uigetfile({'*.csv;*.fbx','Exported Optitrack Files (*.csv,*.fbx)'},...
                        'Select the folder containing *.csv or *.fbx files.',...
                        obj.parameters.defaultLocation.Text,'MultiSelect', 'on');
                end
                obj.parameters.defaultLocation.Text = path;
            end
            if ischar(files)
                files={files};
            end
            for ifile=1:numel(files)
                filename=files{ifile};
                [path1,fname,ext]=fileparts(filename);
                filename=[fname ext];
                switch ext
                    case '.fbx'
                        of=optiTrack.OptiFBXAsciiFile(fullfile(path,filename));
                        ofc=optiTrack.OptiCSVFileSingleMarker(fullfile(path,[fname '.csv']));
                        of.CaptureStartTime=ofc.CaptureStartTime;
                    case '.csv'
                        opts=detectImportOptions(fullfile(path,filename),"ReadVariableNames",false);
                        for i=1:numel(opts.VariableTypes)
                            opts.VariableTypes{i}='char';
                        end
                        opts.DataLines=[3 5];            
                        t=readtable(fullfile(path,filename),opts);
                        if ~strcmpi(t(1,3).Var3,'Marker')
                            if exist('path','var')
                                of=optiTrack.OptiCSVFileRigidBody(fullfile(path,filename));
                            else
                                of=optiTrack.OptiCSVFileRigidBody(fullfile(path1,filename));
                            end
                        else
                            if exist('path','var')
                                of=optiTrack.OptiCSVFileSingleMarker(fullfile(path,filename));
                            else
                                of=optiTrack.OptiCSVFileSingleMarker(fullfile(path1,filename));
                            end
                        end
                end
                if ~exist('ofs','var')
                    ofs=of;
                else
                    ofs=ofs+of;
                end
            end
            f=figure;ofs.plotTimeline;pause(3);close(f);
            pd=ofs.getMergedPositionData;
            pd.source=path;
            pd.saveInPlainFormat(path);
        end

    end
end