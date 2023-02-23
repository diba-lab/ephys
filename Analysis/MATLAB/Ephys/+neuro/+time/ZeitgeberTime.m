classdef ZeitgeberTime < neuro.time.Relative
    %ZEITGEBERTIME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ZeitgeberTime(zt,ref)
            %ZEITGEBERTIME Construct an instance of this class
            %   Detailed explanation goes here
            if exist("ref","var")
                obj.Reference=ref;
            end
            if exist("zt","var")
                obj.Duration=zt;
            end
        end
        
        function zt = getZT0(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            zt=obj.Reference;
        end
        function at = getAbsoluteTime(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            at=obj.Reference+obj.Duration;
        end
    end
end

