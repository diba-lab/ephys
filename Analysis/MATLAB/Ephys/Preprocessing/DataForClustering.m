classdef DataForClustering
    %DATAFORCLUSTERING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Probe
        DataFile
        TimeIntervalCombined
    end
    
    methods
        function obj = DataForClustering(dataFile)
            %DATAFORCLUSTERING Construct an instance of this class
            %   Detailed explanation goes here
            obj.DataFile = dataFile;
        end
        
        function obj = setProbe(obj,probe)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Probe = probe;
        end
        function obj = setTimeIntervalCombined(obj,ticd)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.TimeIntervalCombined = ticd;
        end
        function SykingCircusOutputFolder = runSpyKingCircus(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO 
            
        end
        function SykingCircusOutputFolder = getSpikeOutputfolder(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO 
            
        end
    end
end

