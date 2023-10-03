classdef ScatterData
    %SCATTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimePoints
        DataMatrix
    end
    
    methods
        function obj = ScatterData(time,data)
            %SCATTER Construct an instance of this class
            %   Detailed explanation goes here
            obj.TimePoints = time;
            obj.DataMatrix = data;
        end
    end
end

