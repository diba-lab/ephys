classdef OptiLoader<Singleton
    %OPTILOADER Summary of this class goes here
    %   Detailed explanation goes here

    properties(Access=private)
        parameters
        OptifilesCombined
    end

    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function newObj = OptiLoader(files)
            % Initialise your custom properties.
            s=xml2struct('+optiTrack/configuration.xml');
            fname=fieldnames(s);
            newObj.parameters=s.(fname{1});
            if exist('files','var')
                newObj=newObj.loadFile(files);
            else
                newObj=newObj.loadFile();
            end
        end
    end

    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance(files)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                if nargin>0

                    obj = optiTrack.OptiLoader(files);
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
    methods (Access=private)
        function [obj] = loadFile(obj, files)
            % Just assign the input value to singletonData.  See Singleton
            % superclass.
            if(nargin<2)
                [files, path] = uigetfile({'*.csv;*.fbx','Exported Optitrack Files (*.csv,*.fbx)'},...
                    'Select the folder containing *.csv or *.fbx files.',...
                    obj.parameters.defaultLocation.Text,'MultiSelect', 'on');
                
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
                    case '.csv'
                        %                         of=optiTrack.OptiCSVFileSingleMarker(fullfile(path,files{ifile}));
                        if exist('path','var')
                            of=optiTrack.OptiCSVFileRigidBody(fullfile(path,filename));
                        else
                            of=optiTrack.OptiCSVFileRigidBody(fullfile(path1,filename));
                        end
                end
                if ~exist('ofs','var')
                    ofs=of;
                else
                    ofs=ofs+of;
                end
            end
            obj.OptifilesCombined=ofs;
        end

    end
end