classdef SessionList
    
    properties
        Sessions
    end
    
    methods
        function obj = SessionList(sessions)
            obj.Sessions = sessions;
        end
        
        function tbl = getStateRatioTable(obj)
            
            tbl = obj.Sessions + inputArg;
        end
    end
end

