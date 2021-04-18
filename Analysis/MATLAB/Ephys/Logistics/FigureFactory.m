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
                obj.DefaultPath = '/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout/fooof';
            end
            obj.figtypes={'-dpng','-depsc'};%,'-depsc'
            obj.ext={'.png','.eps'};%,'.eps'
            obj.resolution='-r300';
        end
    end
    methods (Static)
        function obj = instance(defpath)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                try obj = FigureFactory(defpath);catch, obj = FigureFactory();end
                uniqueInstance = obj;
            elseif ~strcmp( uniqueInstance.DefaultPath, defpath)
                uniqueInstance.DefaultPath=defpath;
                obj = uniqueInstance;
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

