classdef OpenEphysRecordDownsampled < openEphys.OpenEphysRecord
    %OPENEPHYSRECORD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        
    end
    
    methods
        function obj = OpenEphysRecordDownsampled(filename)
            obj = obj@openEphys.OpenEphysRecord(filename);
            fileLoaderMethod=obj.getFileLoaderMethod;
            
            oeProperties = fileLoaderMethod.load();
            obj = obj.setData(oeProperties.Data);
            obj = obj.setTimestamps(oeProperties.Timestamps);
            header=oeProperties.Header;
            header.setDataFile(oeProperties.Data.Filename);
            obj = obj.setHeader(header);
        end
        function stateDetectionData = getStateDetectionData(obj,update)
            sessionStruct=BuzcodeFactory.getBuzcode(obj);
            stateDetectionBuzcode=buzcode.StateDetectionBuzcode();
            stateDetectionBuzcode=stateDetectionBuzcode.setBuzcodeStructer(sessionStruct);
            %     stateDetectionBuzcode.overwriteEMGFromLFP
            stateDetectionData=stateDetectionBuzcode.getStates(update);
        end
    end
    %% Functions

    methods (Access=private)
        
    end
end