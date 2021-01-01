classdef Animal <AnimalMeta
    %ANIMAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ProbeMeta
    end
    
    methods
        function obj = Animal(struct)
            %ANIMAL Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@AnimalMeta(struct);
            obj.ProbeMeta=struct.ProbeName;
        end
    end
end

