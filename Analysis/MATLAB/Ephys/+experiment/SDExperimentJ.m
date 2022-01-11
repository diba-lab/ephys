classdef SDExperimentJ < Singleton 
    %SDEXPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        XMLFile
    end
    
    methods
        function obj = SDExperimentJ(varargin)
            %SDEXPER Construct an instance of this class
            %   Detailed explanation goes here
            if exist("xmlfile",'var')
                obj.XMLFile = xmlfile;
            else
            obj.XMLFile = ...
                '/data3/SleepDeprivationDataJ/Experiment.xml';
            end
            try
                S=readstruct(obj.XMLFile);
            catch
                S.FileLocations.General.ExperimentConfig=obj.XMLFile;
                writestruct(S,obj.XMLFile)
            end
            try structstruct(S); catch, end
        end
    end
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance(xmlFile)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                if exist('xmlFile','var')
                    obj = experiment.SDExperimentJ(xmlFile);
                else
                    obj = experiment.SDExperimentJ();
                end
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
                    idx=ismember(sc,state);
                    state1=statecodes(idx);
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

