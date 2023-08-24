classdef DurationNeuroscope
    %DURATIONNEUROSCOPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Duration
    end
    
    methods
        function obj = DurationNeuroscope(duration)
            %DURATIONNEUROSCOPE Construct an instance of this class
            %   Detailed explanation goes here
            obj.Duration = duration;
        end
        
        function str = print(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            str=obj.toString;
            fprintf('%s',str);
        end
        function str = toString(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            dur=obj.Duration;
            min=floor(minutes(dur));
            dur=dur-minutes(min);
            sec=floor(seconds(dur));
            dur=dur-seconds(sec);
            msec=round(seconds(dur)*1000);

            str=sprintf('%d min %d s %d ms',min,sec,msec);
        end
    end
end

