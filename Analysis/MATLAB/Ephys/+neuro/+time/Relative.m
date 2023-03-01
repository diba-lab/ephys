classdef Relative
    %RELATIVETIME Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Duration
        Reference
    end

    methods
        function obj = Relative(time,ref)
            %RELATIVETIME Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                if isduration(time)
                    obj.Duration = time;
                elseif isa(time,'neuro.time.Absolute')
                    obj.Duration = time.time-ref;
                elseif isa(time,'neuro.time.Sample')
                    obj.Duration = time.getDuration;
                end
                obj.Duration.Format='hh:mm:ss.SSSSSS';
                if nargin>1
                    obj.Reference=ref;
                else
                    obj.Reference=[];
                end
            end
        end
        function abs=pointsAbsolute(obj)
            abs=obj.Duration+obj.Reference;
        end
        function abs=points(obj)
            abs=obj.Duration;
        end
        function abs=getReferenceTime(obj)
            abs=obj.Reference;
        end
    end
end

