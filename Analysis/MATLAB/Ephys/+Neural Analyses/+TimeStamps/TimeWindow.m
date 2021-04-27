classdef TimeWindow
    %TIMEWINDOW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        start
        endt
    end
    
    methods
        function obj = TimeWindow(date,length)
            %TIMEWINDOW Construct an instance of this class
            %   Detailed explanation goes here
            obj.start=datetime(date);
            obj.endt=obj.start+length;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

