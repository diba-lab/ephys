classdef OptiLoader<Singleton
    %OPTILOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access=private)
        parameters
        Files
    end
    
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function newObj = OptiLoader(files)
            % Initialise your custom properties.
            s=xml2struct('configuration.xml');
            fname=fieldnames(s);
            newObj.parameters=s.(fname{1});
            try
                newObj=newObj.loadFile(files);
            catch
                newObj=newObj.loadFile();
            end
        end
    end
    
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance(files)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                try
                    obj = OptiLoader(files);
                catch
                    obj = OptiLoader();
                end
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    %*** Define your own methods for SingletonImpl.
    methods % Public Access
        function files=getFiles(obj)
            files= obj.Files;
        end
        function ofc=getOptiFilesCombined(obj)
            files= obj.Files;
            for ifile=1:numel(files)
                file=files{ifile};
                try 
                    ofc=ofc+file;
                catch
                    ofc=file;
                end
            end
        end
        function saveFiles(obj)
            files= obj.Files;
            for ifile=1:numel(files)
                aFile=files{ifile};
                [filepath,name,~]=fileparts(aFile.file);
                save(fullfile(filepath,[name '.mat']),'aFile');
            end
        end
    end
    methods (Access=private)
        function [obj] = loadFile(obj, files)
            % Just assign the input value to singletonData.  See Singleton
            % superclass.
            if(nargin<2)
                [files, path] = uigetfile({'*.csv;*.fbx','Exported Optitrack Files (*.csv,*.fbx)'},...
                    'Select the folder containing *.csv or *.fbx files.',...
                    obj.parameters.defaultLocation.Text,'MultiSelect', 'on');
                if ischar(files)
                    files={files};
                end
                obj.parameters.defaultLocation.Text = path;
            end
            for ifile=1:numel(files)
                filename=files{ifile};
                [path1,fname,ext]=fileparts(filename);
                if ~isempty(path1)
                    path=path1;
                end
                filename=[fname ext];
                switch ext
                    case '.fbx'
                        of=OptiFBXAsciiFile(fullfile(path,filename));
                    case '.csv'
                        of=OptiCSVFileSingleMarker(fullfile(path,files{ifile}));
%                         of=OptiCSVFileRigidBody(fullfile(path,filename));
                end
                ofs{ifile}=of;
            end
            obj.Files=ofs;
        end
        
    end
end