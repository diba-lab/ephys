classdef SessionFactoryJ < experiment.SessionFactory
    %SESSIONFACTORYJ Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = SessionFactoryJ(varargin)
            %SESSIONFACTORYJ Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                args=varargin{:};
            else
                args='/data3/SleepDeprivationDataJ/SessionList.csv';
            end
            obj@experiment.SessionFactory(args)

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
                aSession=experiment.SessionJ(t_sub.PATH{ifile});
                Sde=experiment.SDExperimentJ.instance.get();
                file1=Sde.FileLocations.General.Animals;
                af=experiment.AnimalFactory(file1);
                animal=af.getAnimals(t_sub.ANIMAL(ifile));
                aSession=aSession.setAnimal(animal);
                aSession=aSession.setInjection(t_sub.INJECTION(ifile));
                aSession=aSession.setSleepCondition(t_sub.SLEEP(ifile));
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
                try
                    idx_all=ismember(t.SessionNo,varargin{1});
                catch
                    idx_all=ismember(t.ID,varargin{1});
                end
            else
                for iargin=1:numel(varargin)
                    argin1=varargin{iargin};
                    varnames=t.Properties.VariableNames;
                    varnames=varnames(2:end);
                    idx=false(height(t),1);
                    for ivar=1:numel(varnames)
                        varname=varnames{ivar};
                        try idx=idx|ismember(t.(varname),argin1);catch, end

                    end
                    idx_all=idx_all&idx;
                end
            end
            t_sub=t(idx_all,:);
            t_sub.ANIMAL=categorical(t_sub.ANIMAL);
            t_sub.INJECTION=categorical(t_sub.INJECTION);
            t_sub.SLEEP=categorical(t_sub.SLEEP);
        end
    end
end

