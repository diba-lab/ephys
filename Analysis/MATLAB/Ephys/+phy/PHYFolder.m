classdef PHYFolder
    %PHYFOLDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        folderPath
    end
    
    methods
        function obj = PHYFolder(folder)
            %PHYFOLDER Construct an instance of this class
            %   Detailed explanation goes here
            obj.folderPath = folder;
        end
        
        function sa = getSpikeArray(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            % First read in the data
            sf=neuro.spike.SpikeFactory.instance;
            sa=sf.getPhyOutputFolder(obj.folderPath);
        end
    end
end

