classdef SDExperiment < Singleton
    %SDEXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        XMLFile
    end
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function newObj = SDExperiment()
            % Initialise your custom properties.
            newObj.XMLFile = ...
                '/home/mdalam/Downloads/Analysis_code/jahangir-analysis/Configure_Jahangir/Experiment.xml';
            try
                S=readstruct(newObj.XMLFile);
            catch
                S.FileLocations.General.ExperimentConfig=newObj.XMLFile;
                writestruct(S,newObj.XMLFile)
            end
            try structstruct(S); catch, end
        end
    end
    
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = SDExperiment();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    
    methods
        function S = get(obj)
            S=readstruct(obj.XMLFile);
        end
        function S = set(obj,S)
            writestruct(S,obj.XMLFile);
            S=obj.get;
            try structstruct(S); catch, end
        end
    end
end

