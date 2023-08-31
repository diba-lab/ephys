classdef SDExperimentAged < Singleton
    %SDEXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        XMLFile
    end
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function newObj = SDExperimentAged(xmlfile)
            % Initialise your custom properties.
            if exist("xmlfile",'var')
                newObj.XMLFile = xmlfile;
            else
            newObj.XMLFile = ...
                './ExperimentSpecific/Configure/ExperimentAged.xml';
            end
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
        function obj = instance(xmlFile)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                if exist('xmlFile','var')
                    obj = experiment.SDExperimentAged(xmlFile);
                else
                    obj = experiment.SDExperimentAged();
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
        function colorres = getStateColors(obj,states)
            S=readstruct(obj.XMLFile);
            statestr=fieldnames(S.Colors);
            for ist=1:numel(statestr)
                statecodes(ist)=S.StateCodes.(statestr{ist});
            end
            for ist=1:numel(statestr)
                colors{ist}=S.Colors.(statestr{ist})/255;
            end
            color=containers.Map(statecodes, colors);
            for ist=1:numel(states)
                state=states(ist);
                if exist('state','var')
                    if isnumeric( state)
                        statecode=state;
                    elseif isstring(state)
                        statecode=S.StateCodes.(state);
                    elseif iscategorical(state)
                        statecode=S.StateCodes.(string(state));
                    end
                    colorres(ist,:)=color(statecode);
                end
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
        function params = getAnalysisParams(obj,sesFolder)
            params=readstruct(fullfile(sesFolder, ...
                obj.get.FileLocations.Session.Analysis));
        end
        function S = set(obj,S)
            writestruct(S,obj.XMLFile);
            S=obj.get;
            try structstruct(S); catch, end
        end
    end
end

