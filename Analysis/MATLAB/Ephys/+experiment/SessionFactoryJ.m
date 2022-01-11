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
                animal=af.getAnimals(t_sub.ANIMAL{ifile});
                aSession=aSession.setAnimal(animal);
                aSession=aSession.setInjection(t_sub.INJECTION{ifile});
                aSession=aSession.setSleepCondition(t_sub.SLEEP{ifile});
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
    end
end

