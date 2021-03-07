classdef FigureFactory < Singleton
    %FIGUREFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DefaultPath
        figtypes
        resolution
        ext
    end
    
    methods(Access=private)
        function obj = FigureFactory(defpath)
            %FIGUREFACTORY Construct an instance of this class
            %   Detailed explanation goes here
            if exist('defpath','var')
                if isfolder(defpath)
                    obj.DefaultPath =defpath;
                end
            else
                obj.DefaultPath = '.';
            end
            obj.figtypes={'-dpng'};%,'-depsc'
            obj.ext={'.png'};%,'.eps'
            obj.resolution='-r300';
        end
    end
    methods (Static)
        function obj = instance(defpath)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = FigureFactory(defpath);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        function [] = save(obj,folderfile)
            [filepath,name,~]=fileparts(folderfile);
            if isempty( filepath)
                filepath=obj.DefaultPath;
            end
            if ~isfolder(filepath)
                mkdir(filepath)
            end
            f=gcf;
            f.Renderer='painters';
            folderfile=fullfile(filepath,name);
            for ifig=1:numel(obj.figtypes)
                figtype=obj.figtypes{ifig};
                print([folderfile obj.ext{ifig}],figtype,obj.resolution)
            end
        end
    end
end

