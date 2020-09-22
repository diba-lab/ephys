classdef AnimalMeta<Persist
    %ANIMALMETA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Species
        Strain
        Sex
        Age
        Weight
        GeneticLine
        VirusInjection
        VirusCoordinates
        VirusInjectionDate
        SurgeryDate
        TargetAnatomy
        Anesthesia
        Analgesics
        Antibiotics
        SurgicalComplications
        SurgicalNotes
    end
    
    methods
        function obj = AnimalMeta(file)
            %ANIMALMETA Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@Persist(file);
            T=readtable(file,'ReadRowNames',true);
            obj.Species=T('Species',:).Value{:};
            obj.Strain=T('Strain',:).Value{:};
            obj.Sex=T('Sex',:).Value{:};
            obj.Age=T('Age',:).Value{:};
            obj.Weight=T('Weight',:).Value{:};
            obj.GeneticLine=T('GeneticLine',:).Value{:};
            obj.VirusInjection=T('VirusInjection',:).Value{:};
            obj.VirusCoordinates=T('VirusCoordinates',:).Value{:};
            obj.VirusInjectionDate=T('VirusInjectionDate',:).Value{:};
            obj.SurgeryDate=T('SurgeryDate',:).Value{:};
            obj.TargetAnatomy=T('TargetAnatomy',:).Value{:};
            obj.Anesthesia=T('Anesthesia',:).Value{:};
            obj.Analgesics=T('Analgesics',:).Value{:};
            obj.Antibiotics=T('Antibiotics',:).Value{:};
            obj.SurgicalComplications=T('SurgicalComplications',:).Value{:};
            obj.SurgicalNotes=T('SurgicalNotes',:).Value{:};
        end
        
    end
    methods
        function save(obj)
            S(1).Value=obj.Species;
            S(2).Value=obj.Strain;
            S(3).Value=obj.Sex;
            S(4).Value=obj.Age;
            S(5).Value=obj.Weight;
            S(6).Value=obj.GeneticLine;
            S(7).Value=obj.VirusInjection;
            S(8).Value=obj.VirusCoordinates;
            S(9).Value=obj.VirusInjectionDate;
            S(10).Value=obj.SurgeryDate;
            S(11).Value=obj.TargetAnatomy;
            S(12).Value=obj.Anesthesia;
            S(13).Value=obj.Analgesics;
            S(14).Value=obj.Antibiotics;
            S(15).Value=obj.SurgicalComplications;
            S(16).Value=obj.SurgicalNotes;
            rowNames={...
                'Species',...
                'Strain',...
                'Sex',...
                'Age',...
                'Weight',...
                'GeneticLine',...
                'VirusInjection',...
                'VirusCoordinates',...
                'VirusInjectionDate',...
                'SurgeryDate',...
                'TargetAnatomy',...
                'Anesthesia',...
                'Analgesics',...
                'Antibiotics',...
                'SurgicalComplications',...
                'SurgicalNotes',...
                };
            T=struct2table(S,'RowNames',rowNames);
            writetable(T,obj.FileLocation,'WriteRowNames',true);
        end
    end
end

