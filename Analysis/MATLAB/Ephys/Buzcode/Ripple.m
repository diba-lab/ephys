classdef Ripple
    %RIPPLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PeakTimes
        TimeStamps
        TimeIntervalCombined
        DetectorInfo
        SwMax
        RipMax
    end
    
    methods
        function obj = Ripple(ripple)
            %RIPPLE Construct an instance of this class
            %   Detailed explanation goes here
            obj.PeakTimes=ripple.peaktimes;
            obj.TimeStamps=ripple.timestamps;
            obj.DetectorInfo=ripple.detectorinfo;
            obj.SwMax=ripple.SwMax;
            obj.RipMax=ripple.RipMax;
        end
        
        function outputArg = getNumberOfRipplesChange(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
        function obj = setTimeIntervalCombined(obj,ticd)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.TimeIntervalCombined=ticd;
        end
    end
end

