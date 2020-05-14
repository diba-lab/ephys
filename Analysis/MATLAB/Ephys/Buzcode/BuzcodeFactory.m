classdef BuzcodeFactory
    %BUZCODEFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods (Static)
        function buzcodeStructure = getBuzcode(filePath)
            if isa(filePath,'OpenEphysRecord')
                [filepath,name,ext]=fileparts(filePath.getFile)
                buzcodeStructure=BuzcodeStructure(filepath);
                try buzcodeStructure=buzcodeStructure.SetTimestamps(...
                    filePath.getTimestamps.IsActive);
                catch
                buzcodeStructure=buzcodeStructure.SetTimestamps(...
                    filePath.getTimestamps);
                end
            elseif ischar(filePath)
                buzcodeStructure=BuzcodeStructure(filepath);
            else
                error('What is this bro?')
            end
        end
        
     
    end
end

