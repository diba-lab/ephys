classdef CellMetrics
    %CELLMETRICS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cellMetrics
    end
    
    methods
        function obj = CellMetrics(cellMetricsStruct)
            %CELLMETRICS Construct an instance of this class
            %   Detailed explanation goes here
            obj.cellMetrics =cellMetricsStruct;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

