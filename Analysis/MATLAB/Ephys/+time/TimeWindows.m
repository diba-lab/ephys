classdef (Abstract)TimeWindows
    %TIMEWINDOWS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Abstract)
         timeTabel = getTimeTable(obj)
         obj=mergeOverlaps(obj, minInterwindowInterval)
         merged=plus(obj,newTimeWindows)
         []=plot(obj)
    end
end

