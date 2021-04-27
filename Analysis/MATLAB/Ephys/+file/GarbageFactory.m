classdef GarbageFactory
    %GARBAGEFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods (Static)
        
        function table = getChannelsTable()
            s=load('channels.mat');
            table=s.channels;
        end
    end
end

