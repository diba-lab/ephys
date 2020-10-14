classdef Ripple
    %RIPPLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ripple
    end
    
    methods
        function obj = Ripple(ripple)
            %RIPPLE Construct an instance of this class
            %   Detailed explanation goes here
            obj.ripple=ripple;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

