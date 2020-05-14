classdef AnimalMeta
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
    
        Probes


    end
    
    methods
        function obj = AnimalMeta(inputArg1,inputArg2)
            %ANIMALMETA Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

