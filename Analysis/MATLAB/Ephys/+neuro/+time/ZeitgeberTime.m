classdef ZeitgeberTime < neuro.time.Relative
    %ZEITGEBERTIME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ZeitgeberTime(zt,ref)
            %ZEITGEBERTIME Construct an instance of this class
            %   Detailed explanation goes here
            obj.Reference=ref;
            obj.Duration=zt;
        end
        
        function zt = getZT(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            zt=obj.Reference;
        end
    end
end

