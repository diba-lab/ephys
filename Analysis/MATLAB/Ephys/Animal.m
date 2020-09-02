classdef Animal <AnimalMeta
    %ANIMAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ProbeMeta
        Records
    end
    
    methods
        function obj = Animal(file)
            %ANIMAL Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@AnimalMeta(file);
        end
        
        function outputArg = addProbeMeta(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
        function []=save(obj)
            try
                save@AnimalMeta(obj)
            catch
                
            end
            try
                obj.Probe.saveProbeTable
            catch
                
            end
        end
    end
end

