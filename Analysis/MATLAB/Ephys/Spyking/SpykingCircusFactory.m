classdef SpykingCircusFactory
    %SPKINGC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods (Static)
        function oer = runSpyking(oer,shank)
            system('conda init bash','-echo')
            system('conda activate circus','-echo')
        end
    end
    
end
