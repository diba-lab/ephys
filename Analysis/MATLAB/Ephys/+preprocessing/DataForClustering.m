classdef DataForClustering
    %DATAFORCLUSTERING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DataFile
        Probe
        TimeIntervalCombined
    end
    
    methods
        function obj = DataForClustering(dataFile)
            %DATAFORCLUSTERING Construct an instance of this class
            %   Detailed explanation goes here
            try
                ef=EphysFolder(dataFile);
                obj.DataFile=ef.Data;
            catch
                obj.DataFile=dataFile;
            end
            try
                obj.Probe=Probe(ef.Channel);
            catch
                warning(sprintf('No Probe File'))
            end
            try
                obj.TimeIntervalCombined=TimeIntervalCombined(ef.Time);
            catch
                warning(sprintf('No Time File'))
            end        
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
            folder='/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/Configure/Kilosort';
            S=readstruct(fullfile(folder,'Kilosort.xml'));
            probe=obj.getProbe;
            dataFile=obj.getDataFile;
            ticd=obj.getTime;
            %% you need to change most of the paths in this block
            
            addpath(genpath(S.KilosortFolder)) % path to kilosort folder
            addpath(S.npy_matlabFolder) % for converting to Phy
            rootZ = fileparts(dataFile); % the raw data binary file is in this folder
            rootH = S.SSDFolder; % path to temporary binary file (same size as data, should be on fast SSD)
            pathToYourConfigFile = folder; % take from Github folder and put it somewhere else (together with the master_file)
            
            kcm=preprocessing.cluster.kilosort.KilosortChannelMap(probe,ticd.getSampleRate);
            chanMapFile=fullfile(rootZ,'chanMap.mat');
            kcm.createChannelMapFile(chanMapFile);
            
            run(fullfile(pathToYourConfigFile, 'configFile384.m'))
            ops.trange    = [0 Inf]; % time range to sort
            ops.NchanTOT  = numel(probe.getActiveChannels); % total number of channels in your recording
            
            ops.fproc   = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD
            ops.chanMap = char( chanMapFile);
            % sample rate
            ops.fs =ticd.getSampleRate;  
            %% this block runs all the steps of the algorithm
            fprintf('Looking for data inside %s \n', rootZ)
            
            % main parameter changes from Kilosort2 to v2.5
            
            ops.fbinary = dataFile;
            %% Based on the comment in github issue https://github.com/MouseLand/Kilosort/issues/333
            % see also https://www.mathworks.com/matlabcentral/answers/309235-can-i-use-my-nvidia-pascal-architecture-gpu-with-matlab-for-gpu-computing
            % 
            setenv("CUDA_CACHE_MAXSIZE","1073741824");%% bytes, 1GB -->1024*1024*1024. Default is 32MB.
            %%
            rez                = preprocessDataSub(ops);
            rez                = datashift2(rez, 1);
            
            [rez, st3, tF]     = extract_spikes(rez);
            
            rez                = template_learning(rez, tF, st3);
            
            [rez, st3, tF]     = trackAndSort(rez);
            
            rez                = final_clustering(rez, tF, st3);
            
            rez                = find_merges(rez, 1);
            
            rootZ = fullfile(rootZ, 'kilosort3');
            mkdir(rootZ)
            rezToPhy2(rez, rootZ);
            
            %%
        end
        function SykingCircusOutputFolder = getSpikeOutputfolder(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO
            
        end
    end
end

