classdef TimeFrequencyEnhance
    %TIMEFREQUENCYENHANCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TFMap
    end
    
    methods
        function obj = TimeFrequencyEnhance()
           
        end
        
        function obj = addTimeFrequencyEnhance(obj,TFMap)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.TFMap = TFMap;
        end
    end
end

