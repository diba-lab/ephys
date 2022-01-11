classdef CellMetrics
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CellMetricsStruct
    end
    
    methods
        function obj = CellMetrics(basepaths)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            if iscell(basepaths)
                obj.CellMetricsStruct = loadCellMetricsBatch('basepaths',basepaths);
            else
                obj.CellMetricsStruct = loadCellMetrics('basepath',basepaths);
            end
        end
        function filter=getFilter(obj)
            cm=obj.CellMetricsStruct;
            fns=fieldnames(cm);
            for ifn=1:numel(fns)
                fn=fns{ifn};
                if iscell(cm.(fn))
                    filter.(fn)=unique(cm.(fn));
                elseif isnumeric(cm.(fn))
                    filter.(fn)=[min(cm.(fn)) max(cm.(fn))];
                else
                end
            end
        end

    end
    
end

