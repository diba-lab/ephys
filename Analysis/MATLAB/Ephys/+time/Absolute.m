classdef Absolute
    %ABSOLUTETIME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time
    end
    
    methods
        function obj = Absolute(time,ref)
            if isdatetime(time)||isa(time,'time.Absolute')
                obj.time = time;
            elseif isa(time,'time.Relative')
                obj.time = time.duration+ref;
            elseif isduration(time)
                obj.time = duration+ref;
            elseif isa(time,'time.Sample')
                obj.time = time.getDuration+ref;
            end
            obj.time.Format='dd-MMM-uuuu HH:mm:ss.SSSSSS';
        end
        function time = getTime(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            time = obj.time-obj.getDate;
        end
        function date = getDate(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            date=datetime(obj.time.Year,obj.time.Month,obj.time.Day);
        end
        function pts = points(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pts=obj.time;
        end
    end
end

