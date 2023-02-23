classdef SpikePhases < neuro.phase.Polar
    %SPIKEPHASES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        UnitInfo

    end
    
    methods
        function obj = SpikePhases(phasetable,varargin)
            %SPIKEPHASES Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                obj.PolarData=phasetable;
                if nargin>1
                    obj.UnitInfo=varargin{1};
                end
            end
        end
        
        function phases = getPhase(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            phases = obj.PolarData.Phase;
        end
    end
end

