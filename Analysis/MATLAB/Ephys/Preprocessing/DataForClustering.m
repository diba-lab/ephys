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
        function pr = getProbe(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pr=obj.Probe;
        end
        function df = getDataFile(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            df=obj.DataFile;
        end
        function t = getTime(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t=obj.TimeIntervalCombined;
        end
        function SykingCircusOutputFolder = runSpyKingCircus(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO 
            
        end
        function [] = runKilosort3(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO 
            probe=obj.getProbe;
            dataFile=obj.getDataFile;
            ticd=obj.getTime;
            
        end
        function SykingCircusOutputFolder = getSpikeOutputfolder(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO 
            
        end
    end
end

