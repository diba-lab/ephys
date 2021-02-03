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
        function obj = FigureFactory()
            %FIGUREFACTORY Construct an instance of this class
            %   Detailed explanation goes here
            obj.DefaultPath = '/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout';
            obj.figtypes={'-dpng'};%,'-depsc'
            obj.ext={'.png'};%,'.eps'
            obj.resolution='-r300';
        end
    end
    methods (Static)
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = FigureFactory();
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

