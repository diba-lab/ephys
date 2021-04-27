classdef AnimalFactory
    %SESIONFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        AnimalsStruct
    end
    
    methods
        function obj = AnimalFactory()
            %SESIONFACTORY Construct an instance of this class
            %   Detailed explanation goes here
            
            Sde=SDExperiment.instance.get();
            try
                S1=readstruct(Sde.FileLocations.General.Animals);
            catch
                animal.Age='';
                animal.Analgesics='';
                animal.Anesthesia='';
                animal.Antibiotics='';
                animal.Code='';
                animal.GeneticLine='';
                animal.Sex='';
                animal.Species='';
                animal.Strain='';
                animal.SurgeryDate='';
                animal.SurgicalComplications='';
                animal.SurgicalNotes='';
                animal.TargetAnatomy='';
                animal.VirusCoordinates='';
                animal.VirusInjection='';
                animal.VirusInjectionDate='';
                animal.Weight='';
                animal.ProbeName='';
                S1.animals(1)=animal;
                S1.animals(2)=animal;
                writestruct(S1,Sde.FileLocations.General.Animals);
            end
            obj.AnimalsStruct=S1.animals;
        end
        function animals = getAnimals(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            animalstruct=obj.AnimalsStruct;
            idx_all=true(numel(animalstruct),1);
            if nargin<2
                display(animalstruct);
                
            elseif nargin==2 && isnumeric( varargin{1})
                    idx_all(:)=false;
                    idx_all(varargin{1})=true;
            else
                for iargin=1:numel(varargin)
                    argin1=varargin(iargin);
                    varnames=fieldnames(animalstruct);
                    idx=false(numel(animalstruct),1);
                    for ivar=1:numel(varnames)
                        varname=varnames{ivar};
                        try idx=idx|ismember([animalstruct.(varname)],argin1)';catch, end
                        
                    end
                    idx_all=idx_all&idx;
                end
            end
            animalstruct=animalstruct(idx_all);
            for ianimal=1:numel(animalstruct)
                animals(ianimal)=Animal(animalstruct(ianimal));
            end
        end
    end
end

