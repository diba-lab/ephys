classdef FigureFactory < Singleton
    %FIGUREFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DefaultPath
        resolution
        ext
    end
    
    methods(Access=private)
        function obj = FigureFactory(defpath)
            %FIGUREFACTORY Construct an instance of this class
            %   Detailed explanation goes here
            if exist('defpath','var')
                if ~isfolder(defpath)
                    mkdir(defpath)
                end
                obj.DefaultPath =defpath;
            else
                obj.DefaultPath = pwd;
            end
            obj.ext={'.pdf'}; %,'.png','.eps'
            obj.resolution=300;
        end
    end
    methods (Static)
        function obj = instance(defpath)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                try obj = logistics.FigureFactory(defpath);
                catch, obj = logistics.FigureFactory();end
                uniqueInstance = obj;
            else
                obj = uniqueInstance;    
                try obj.DefaultPath=defpath;catch, end
            end
        end
    end
    methods
        function [] = save(obj,folderfile)
            [filepath,name,~]=fileparts(folderfile);
            if isempty( filepath)||strcmp("",filepath)
                filepath=obj.DefaultPath;
            end
            if ~isfolder(filepath)
                mkdir(filepath)
            end
            f=gcf;
            f.Renderer='painters';
            folderfile=fullfile(filepath,matlab.lang.makeValidName(name));
            for ifig=1:numel(obj.ext)
                figtype=obj.ext{ifig};
                if strcmp(figtype,'.pdf')
                    exportgraphics(f,strcat(folderfile, obj.ext{ifig}), ...
                        'Resolution',obj.resolution, ...
                        'ContentType','vector', ...
                        'Append',true)
                else
                    exportgraphics(f,strcat(folderfile, obj.ext{ifig}), ...
                        'Resolution',obj.resolution)
                end
            end
        end
    end
end

