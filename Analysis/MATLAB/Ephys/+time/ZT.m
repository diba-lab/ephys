classdef ZT<time.ZeitgeberTime
    %ZT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = ZT(varargin)
            obj=obj@time.ZeitgeberTime(varargin{:})
        end
    end
end

