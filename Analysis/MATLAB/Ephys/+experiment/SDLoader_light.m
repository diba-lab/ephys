classdef SDLoader_light < SDLoader
    %SDLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
    end
    methods(Access = private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function newObj = SDLoader_light()
            % Initialise your custom properties.
            newObj.datafolder='/data/EphysAnalysis/SleepDeprivationData';
            newObj.eventData=[];
        end
    end
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = SDLoader_light();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    methods
        function day1 = getRat_AG_Day01_SD(obj,varargin)
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day01_SD';
            i=0;
            i=i+1;files{i}='/continuous_04-01-10_08-06-28_down-sampled-1250/continuous_04-01-10_08-06-28_down-sampled-1250.lfp';
            i=i+1;files{i}='/continuous_08-10-37_12-59-53_down-sampled-1250/continuous_08-10-37_12-59-53_down-sampled-1250.lfp';
            i=i+1;files{i}='/continuous_13-18-34_14-57-00_down-sampled-1250/continuous_13-18-34_14-57-00_down-sampled-1250.lfp';
            i=i+1;files{i}='/continuous_15-00-00_18-45-27_down-sampled-1250/continuous_15-00-00_18-45-27_down-sampled-1250.lfp';
            
            i=0;
            i=i+1;videos{i}='Take 2019-12-22 04.01.06 AM-REST-frozen at some time-Camera 3 (#410110).avi';
            i=i+1;videos{i}='Take 2019-12-22 08.11.07 AM-SD-Camera 3 (#410110)@1.avi';
            i=i+1;videos{i}='Take 2019-12-22 08.11.07 AM-SD-Camera 3 (#410110)@25001.avi';
            i=i+1;videos{i}='Take 2019-12-22 08.11.07 AM-SD-Camera 3 (#410110)@50001.avi';
            i=i+1;videos{i}='Take 2019-12-22 08.11.07 AM-SD-Camera 3 (#410110)@75001.avi';
            i=i+1;videos{i}='Take 2019-12-22 08.11.07 AM-SD-Camera 3 (#410110)@100001.avi';
            i=i+1;videos{i}='Take 2019-12-22 01.18.30 PM-TRACK1-Camera 3 (#410110).avi';
            i=i+1;videos{i}='Take 2019-12-22 01.29.44 PM-TRACK2-Camera 3 (#410110).avi';
            i=i+1;videos{i}='Take 2019-12-22 01.30.57 PM-TRACK3-Camera 3 (#410110).avi';
            
            i=0;
            i=i+1;tracks{i}='Take 2019-12-22 04.01.06 AM-REST-frozen at some time.fbx';
            i=i+1;tracks{i}='Take 2019-12-22 08.11.07 AM-SD.fbx';
            i=i+1;tracks{i}='Take 2019-12-22 01.18.30 PM-TRACK1.fbx';
            i=i+1;tracks{i}='Take 2019-12-22 01.30.57 PM-TRACK3.fbx';
            i=i+1;tracks{i}='Take 2019-12-22 03.00.03 PM-POST.fbx';
            
            i=0;
            i=i+1;events{i}='AG_2019-12-2-Day01-SD.csv';
            %             i=i+1;events{i}='AG_2019-12-22-Day01_SD_track.csv';
            
            obj=obj.loadTrackFiles(fullfile(obj.activeWorkspaceFile,tracks));
            
            obj=obj.loadOERFiles(fullfile(obj.activeWorkspaceFile,files));
            obj=obj.loadVideoFiles(fullfile(obj.activeWorkspaceFile,videos));
            obj=obj.loadEventFiles(fullfile(obj.activeWorkspaceFile,events));
            day1=SDDay('Day01',obj.activeWorkspaceFile);
            day1=day1.setOpenEphysRecordCombined(obj.activeOpenEphysRecord);
            day1=day1.setOptiFileCombined(obj.tracks);
            day1=day1.setVideoFilesCombined(obj.videos);
            day1=day1.setEventData(obj.eventData);
        end
        function day1 = getRat_AG_Day02_NSD(obj)
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day02_NSD';
            files{1}='/continuous_05-00-08_08-00-07_down-sampled-1250/continuous_05-00-08_08-00-07_down-sampled-1250.lfp';
            files{2}='/continuous_08-04-18_12-59-53_down-sampled-1250/continuous_08-04-18_12-59-53_down-sampled-1250.lfp';
            files{3}='/continuous_13-12-48_14-52-31_down-sampled-1250/continuous_13-12-48_14-52-31_down-sampled-1250.lfp';
            files{4}='/continuous_15-01-45_18-27-11_down-sampled-1250/continuous_15-01-45_18-27-11_down-sampled-1250.lfp';
            
            i=0;
            i=i+1;videos{i}='Take 2019-12-23 04.58.15 AM-REST-Camera 3 (#410110).avi';
            i=i+1;videos{i}='Take 2019-12-23 08.04.21 AM-NSD-Camera 3 (#410110).avi';
            %             i=i+1;videos{i}='Take 2019-12-23 01.42.50 PM-TRACK-Camera 3 (#410110).avi';
            i=i+1;videos{i}='Take 2019-12-23 02.59.02 PM-POST-Camera 3 (#410110).avi';
            i=i+1;videos{i}='Take 2019-12-23 03.45.01 PM-POST-Camera 3 (#410110).avi';
            i=i+1;videos{i}='Take 2019-12-23 03.48.45 PM-POST-Camera 3 (#410110).avi';
            
            i=0;
            i=i+1;tracks{i}='Take 2019-12-23 04.58.15 AM-REST.fbx';
            i=i+1;tracks{i}='Take 2019-12-23 08.04.21 AM-NSD.fbx';
            i=i+1;tracks{i}='Take 2019-12-23 01.42.50 PM-TRACK.fbx';
            i=i+1;tracks{i}='Take 2019-12-23 02.59.02 PM-POST.fbx';
            i=i+1;tracks{i}='Take 2019-12-23 03.45.01 PM-POST.fbx';
            i=i+1;tracks{i}='Take 2019-12-23 03.48.45 PM-POST.fbx';
            
            i=0;
            i=i+1;events{i}='AG_2019-12-23-Day02_NSD_track.csv';
            
            obj=obj.loadTrackFiles(fullfile(obj.activeWorkspaceFile,tracks));
            obj=obj.loadOERFiles(fullfile(obj.activeWorkspaceFile,files));
            obj=obj.loadVideoFiles(fullfile(obj.activeWorkspaceFile,videos));
            %             obj=obj.loadEventFiles(fullfile(obj.activeWorkspaceFile,events));
            day1=SDDay('Day02',obj.activeWorkspaceFile);
            day1=day1.setOpenEphysRecordCombined(obj.activeOpenEphysRecord);
            day1=day1.setOptiFileCombined(obj.tracks);
            day1=day1.setVideoFilesCombined(obj.videos);
            day1=day1.setEventData(obj.eventData);
        end
        function day = getRat_AG_Day03_SD(obj)
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day03_SD';
            files{1}='/continuous_05-06-16_08-06-15_down-sampled-1250/continuous_05-06-16_08-06-15_down-sampled-1250.lfp';
            files{2}='/continuous_08-11-18_12-48-36_down-sampled-1250/continuous_08-11-18_12-48-36_down-sampled-1250.lfp';
            files{3}='/continuous_12-54-49_15-05-10_down-sampled-1250/continuous_12-54-49_15-05-10_down-sampled-1250.lfp';
            files{4}='/continuous_15-09-42_18-15-09_down-sampled-1250/continuous_15-09-42_18-15-09_down-sampled-1250.lfp';
            obj=obj.loadOERFiles(fullfile(obj.activeWorkspaceFile,files));
            day=SDDay('Day03',obj.activeWorkspaceFile);
            day=day.setOpenEphysRecordCombined(obj.activeOpenEphysRecord);
            
        end
        function day = getRat_AG_Day04_NSD(obj)
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day04_NSD';
            files{1}='/Continuous_Data_04-49-48_10-34-14_down-sampled-1250/Continuous_Data_04-49-48_10-34-14_down-sampled-1250.lfp';
            files{2}='/Continuous_Data_2_10-35-36_13-05-15_down-sampled-1250/Continuous_Data_2_10-35-36_13-05-15_down-sampled-1250.lfp';
            files{3}='/Continuous_Data_4_13-28-31_14-49-28_down-sampled-1250/Continuous_Data_4_13-28-31_14-49-28_down-sampled-1250.lfp';
            files{4}='/continuous_14-53-37_20-03-08_down-sampled-1250/continuous_14-53-37_20-03-08_down-sampled-1250.lfp';
            obj=obj.loadOERFiles(fullfile(obj.activeWorkspaceFile,files));
            day=SDDay('Day04',obj.activeWorkspaceFile);
            day=day.setOpenEphysRecordCombined(obj.activeOpenEphysRecord);

        end
        function obj = getRat_AG_Day05_SD(obj)
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day05_SD';
            files{1}='/continuous_05-15-10_08-24-42_down-sampled-1250/continuous_05-15-10_08-24-42_down-sampled-1250.lfp';
            files{2}='/continuous_08-11-17_12-19-39_down-sampled-1250/continuous_08-11-17_12-19-39_down-sampled-1250.lfp';
            files{3}='/continuous_12-20-49_12-57-52_down-sampled-1250/continuous_12-20-49_12-57-52_down-sampled-1250.lfp';
            files{4}='/continuous_13-05-51_14-32-16_down-sampled-1250/continuous_13-05-51_14-32-16_down-sampled-1250.lfp';
            files{5}='/continuous_14-38-38_14-41-29_down-sampled-1250/continuous_14-38-38_14-41-29_down-sampled-1250.lfp';
            files{6}='/continuous_14-44-16_18-41-26_down-sampled-1250/continuous_14-44-16_18-41-26_down-sampled-1250.lfp';
            oerc=obj.loadOERFiles(fullfile(obj.activeWorkspaceFile,files));
        end
        function obj = getRat_AG_Day06_NSD(obj)
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day06_NSD';
            files{1}='/continuous_05-13-18_08-02-53_down-sampled-1250/continuous_05-13-18_08-02-53_down-sampled-1250.lfp';
            files{2}='/continuous_08-20-17_13-01-55_down-sampled-1250/continuous_08-20-17_13-01-55_down-sampled-1250.lfp';
            files{3}='/continuous_13-19-06_15-34-24_down-sampled-1250/continuous_13-19-06_15-34-24_down-sampled-1250.lfp';
            files{4}='/continuous_15-38-30_19-07-28_down-sampled-1250/continuous_15-38-30_19-07-28_down-sampled-1250.lfp';
            oerc=obj.loadOERFiles(fullfile(obj.activeWorkspaceFile,files));
        end
    end
end

