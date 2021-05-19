classdef TimeFactory
    %TIMEFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods (Static)
        function r = getHHMMSS()
            r='HH:MM:SS';
        end
        function r = getddmmmyyyyHHMMSSFFF()
            r='dd-mmm-yyyy HH:MM:SS.FFF';
        end
        function r = getddmmmyyyyHHMMSS()
            r='yyyy-MM-dd HH:mm:ss';
        end
        function r = getyyyyMMddhhmmssa()
            r='yyyy-MM-dd hh.mm.ss a';
        end
        function r = getddmmyyyyHHmmSS()
            r='dd MMM yyyy HH:mm:ss';
        end
        
    end
end

