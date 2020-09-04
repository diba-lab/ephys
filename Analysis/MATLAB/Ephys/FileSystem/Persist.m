classdef (Abstract) Persist
    %PERSIST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FileLocation
    end
    methods (Abstract)
        save(obj)
    end
    methods
        function obj = Persist(fileLocation)
            %PERSIST Construct an instance of this class
            %   Detailed explanation goes here
            obj.FileLocation=fileLocation;
        end      
    end
end

