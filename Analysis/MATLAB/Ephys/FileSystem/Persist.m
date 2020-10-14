classdef (Abstract) Persist
    %PERSIST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    methods (Abstract)
        saveObject(obj,location)
    end
    methods
        function obj = Persist()
            %PERSIST Construct an instance of this class
            %   Detailed explanation goes here
        end
        function saveBasedOn(obj,data,folder)
            str=DataHash(data);
            if ~isfolder(fullfile(folder,'cache'))
                mkdir(fullfile(folder,'cache'));
            end
            save(fullfile(folder,'cache',str),'obj');   
        end
    end
end

