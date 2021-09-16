classdef Relative
    %RELATIVETIME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        duration
    end
    
    methods
        function obj = Relative(time,ref)
            %RELATIVETIME Construct an instance of this class
            %   Detailed explanation goes here
            if isduration(time)
                obj.duration = time;
            elseif isa(time,'neuro.time.Absolute')
                obj.duration = time.time-ref;
            elseif isa(time,'neuro.time.Sample')
                obj.duration = time.getDuration;
            end
            obj.duration.Format='hh:mm:ss.SSSSSS';
        end
    end
end

