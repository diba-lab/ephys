classdef SessionBuz < experiment.Session
    %SESSIONBUZ Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = SessionBuz(varargin)
            %SESSIONBUZ Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@experiment.Session(varargin{:});
        end
        
        function units = getUnits(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
        end
    end
end

