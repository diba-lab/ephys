classdef SWRipple < neuro.ripple.RippleAbs
    %RIPPLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PeakTimes
        SwMax
        RipMax
    end
    
    methods
        function obj = SWRipple(ripple)
            obj.PeakTimes.start=ripple.timestamps(:,1);
            obj.PeakTimes.peak=ripple.peaktimes;
            obj.PeakTimes.stop=ripple.timestamps(:,2);
            obj.SwMax=ripple.SwMax(:,1);
            obj.RipMax=ripple.RipMax(:,1);
            obj.DetectorInfo=ripple.detectorinfo;
        end
        function peakTimes= getPeakTimes(obj)
            peakTimes=obj.PeakTimes.peak;
        end
        function peakTimes= getStartStopTimes(obj)
            peakTimes(:,1)=obj.PeakTimes.start;
            peakTimes(:,2)=obj.PeakTimes.stop;
        end
        function ripmax= getRipMax(obj)
            ripmax=obj.RipMax;
        end
        function swmax= getSwMax(obj)
            swmax=obj.SwMax;
        end
    end
end

