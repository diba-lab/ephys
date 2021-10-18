classdef SessionFactory
    %SESIONFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SessionsFile
    end
    
    methods
        function obj = SessionFactory(varargin)
            %SESIONFACTORY Construct an instance of this class
            %   Detailed explanation goes here
            l=logging.Logger.getLogger;
            if nargin==0
                S=experiment.SDExperiment.instance.get();
                file1=S.FileLocations.General.Sessions;
            else
                file1=varargin{1};
            end
            T=readtable(file1,'Delimiter',',');
            l.info('Session List: %s \n\t%s', file1, strjoin(T.Properties.VariableNames,', '))
            obj.SessionsFile=T;
        end
        function sessions = getSessions(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if nargin<2
                t_sub=obj.getSessionsTable();
            else
                t_sub=obj.getSessionsTable(varargin{:});
            end
            for ifile=1:height(t_sub)
                aSession=experiment.Session(t_sub.Filepath{ifile});
                af=experiment.AnimalFactory;
                animal=af.getAnimals(t_sub.animal{ifile});
                aSession=aSession.setAnimal(animal);
                aSession=aSession.setCondition(t_sub.Condition{ifile});
                if isempty(aSession.Probe)
                    probe=animal.getProbe;
                    if ~isempty(probe)
                        aSession=aSession.setProbe(probe);
                    else
                        aSession=aSession.setProbe();
                    end
                end
                sessions(ifile)=aSession;
            end
        end
        function t_sub = getSessionsTable(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t=obj.SessionsFile;
            idx_all=true(height(t),1);
            if nargin<2, display(t);
                
            elseif nargin==2 && isnumeric( varargin{1})
                    idx_all(:)=false;
                    idx_all(varargin{1})=true;
            else
                for iargin=1:numel(varargin)
                    argin1=varargin{iargin};
                    varnames=t.Properties.VariableNames;
                    idx=false(height(t),1);
                    for ivar=1:numel(varnames)
                        varname=varnames{ivar};
                        try idx=idx|ismember(t.(varname),argin1);catch, end
                        
                    end
                    idx_all=idx_all&idx;
                end
            end
            t_sub=t(idx_all,:);
        end
    end
end

