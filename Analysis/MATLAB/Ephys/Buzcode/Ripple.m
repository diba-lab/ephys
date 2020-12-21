classdef Ripple < RippleAbs
    %RIPPLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PeakTimes
        RipplePower
    end
    
    methods
        function obj = Ripple(ripple)
            obj.PeakTimes.start=ripple.timestamps(:,1);
            obj.PeakTimes.peak=ripple.peaks;
            obj.PeakTimes.stop=ripple.timestamps(:,2);
            obj.RipplePower=ripple.peakNormedPower;
            obj.DetectorInfo=ripple.detectorinfo;
            
        end
        function peakTimes= getPeakTimes(obj)
            peakTimes=obj.PeakTimes.peak;
        end
        function peakTimes= getStartStopTimes(obj)
            peakTimes(:,1)=obj.PeakTimes.start;
            peakTimes(:,2)=obj.PeakTimes.stop;
        end
        function power= getRipplePower(obj)
            power=obj.RipplePower;
        end
        

    end
end

