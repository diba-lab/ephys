classdef ProbeCellExplorer< neuro.probe.Probe
    %PROBECELLEXPLORER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = ProbeCellExplorer(varargin)
            %PROBECELLEXPLORER Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@neuro.probe.Probe(varargin{:});
        end
        
        function outputArg = saveChannelMap(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

        end
    end
end

