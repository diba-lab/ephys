classdef BuzcodeStructure
    %BUZCODESTRUCTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DataSetFolder
        RecordingName
        basePath
        timestamps
    end
    
    methods
        function obj = BuzcodeStructure(basePath)
            %Select from no input
            if ~exist('basePath','var')
                basePath = uigetdir(cd,...
                    'Which recording(s) would you like to state score?');
                if isequal(basePath,0);return;end
            end
            
            %Separate datasetfolder and recordingname
            [obj.DataSetFolder,recordingname,extension] = fileparts(basePath);
            obj.RecordingName= [recordingname,extension]; % fileparts parses '.' into extension
            obj.basePath=basePath;
            
            %% If there is no .lfp in basePath, choose (multiple?) folders within basePath.
            %Select from dataset folder - need to check if .xml/lfp exist
            if ~exist(fullfile(obj.DataSetFolder,recordingname,[recordingname,'.lfp']),'file') && ...
                    ~exist(fullfile(obj.DataSetFolder,recordingname,[recordingname,'.eeg']),'file')
                display(['no .lfp file in basePath, pick a selection of session folders',...
                    'containing .lfp files'])
            end
        end
        function obj=SetTimestamps(obj,ts)
            obj.timestamps=ts;
        end
    end
end

