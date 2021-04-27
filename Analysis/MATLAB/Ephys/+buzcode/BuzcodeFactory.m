classdef BuzcodeFactory
    %BUZCODEFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods (Static)
        function buzcodeStructure = getBuzcode(filepath)
            if ~exist('filepath','var')
                buzcodeStructure=BuzcodeStructure();
            elseif isa(filepath,'OpenEphysRecord')
                [filepath,name,ext]=fileparts(filepath.getFile);
                buzcodeStructure=BuzcodeStructure(filepath);
            elseif ischar(filepath)||isstring(filepath)
                buzcodeStructure=BuzcodeStructure(filepath);
            else
                error('What is this bro?')
            end
        end
        
        
    end
end

