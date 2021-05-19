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
                './ExperimentSpecific/Configure/Experiment.xml';
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
                obj = experiment.SDExperiment();
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
        function color = getStateColors(obj,state)
            S=readstruct(obj.XMLFile);
            statestr=fieldnames(S.Colors);
            for ist=1:numel(statestr)
                statecodes(ist)=S.StateCodes.(statestr{ist});
            end
            for ist=1:numel(statestr)
                colors{ist}=S.Colors.(statestr{ist})/255;
            end
            color=containers.Map(statecodes, colors);
            if exist('state','var')
                if isnumeric( state)
                    statecode=state;
                else
                    statecode=S.StateCodes.(state);
                end
                color=color(statecode);
            end
        end
        function state1 = getStateCode(obj,state)
            S=readstruct(obj.XMLFile);
            sc=fieldnames(   S.StateCodes);
            for ist=1:numel(sc)
                statecodes(ist)=S.StateCodes.(sc{ist}); %#ok<AGROW>
            end
            states=containers.Map(statecodes, sc);
           
            if exist('state','var')
                if isnumeric( state)
                    state1=states(state);
                    
                else
                    state1=S.StateCodes.(state);
                end
            end
        end
        function S = set(obj,S)
            writestruct(S,obj.XMLFile);
            S=obj.get;
            try structstruct(S); catch, end
        end
    end
end

