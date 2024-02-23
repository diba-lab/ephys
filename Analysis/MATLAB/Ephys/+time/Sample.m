classdef Sample
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sample
        rate
    end
    
    methods
        function obj = Sample(time,rate)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            if isnumeric(time)
                obj.sample = time;
                obj.rate=rate;
            elseif isa(time,'time.Relative')
                obj.sample=seconds(time.duration)*rate;
                obj.rate=rate;
            end
        end
        
        function duration = getDuration(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            duration = seconds(double(obj.sample)/obj.rate);
            duration.Format='hh:mm:ss.SSSSSS';
        end
    end
end

