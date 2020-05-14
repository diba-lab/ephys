classdef Spikes
    %SPIKES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        recordParams % this class includes start time and sampling frequency
        spikeTimeTable % this shoud have 2 columns: Time, Cluster number
    end
    
    methods
        function obj = Spikes(table, recordParams)
            %SPIKES Construct an instance of this class
            %   Detailed explanation goes here
            obj.spikeTimeTable = table;
            obj.recordParams = recordParams;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

