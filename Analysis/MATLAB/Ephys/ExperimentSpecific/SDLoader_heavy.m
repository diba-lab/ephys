classdef SDLoader_heavy < SDLoader
    %SDLOADER Summary of this class goes here
    %   Detailed explanation goes here
    properties(Access = private)
    end
    methods(Access = private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function newObj = SDLoader_heavy()
            % Initialise your custom properties.
            newObj.datafolder='/data2/gdrive/ephys/AG/Day04_NSD';
        end
    end
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = SDLoader_heavy();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        function oerc = getRat_AG_Day01_SD(obj,varargin)
            path='/data2/gdrive/ephys/AG/Day01_SD';
            files{1}='/AG_2019-12-22_04-01-10_REST-SD/experiment1/recording1/structure.oebin';
            files{2}='/AG_2019-12-22_04-01-10_REST-SD/experiment1/recording2/structure.oebin';
            files{3}='/AG_2019-12-22_13-00-34_TRACK/experiment2/recording1/structure.oebin';
            files{4}='/AG_2019-12-22_14-57-46_POST/experiment3/recording1/structure.oebin';
            oerc=obj.loadOERFiles(fullfile(path,files));
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day01_SD';
        end
        function oerc = getRat_AG_Day02_NSD(obj)
            path='/data2/gdrive/ephys/AG/Day02_NSD';
            files{1}='/AG_2019-12-23_05-00-08_REST/experiment1/recording1/structure.oebin';
            files{2}='/AG_2019-12-23_08-04-14-NSD/experiment2/recording1/structure.oebin';
            files{3}='/AG_2019-12-23_13-12-45_TRACK/experiment3/recording1/structure.oebin';
            files{4}='/AG_2019-12-23_14-59-22_POST/experiment5/recording1/structure.oebin';
            oerc=obj.loadOERFiles(fullfile(path,files));
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day02_NSD';
        end
        function oerc = getRat_AG_Day03_SD(obj)
            path='/data2/gdrive/ephys/AG/Day03_SD';
            %             files{1}='/AG_2019-12-26_04-57-08_REST_SD_TRACK/experiment1/recording1/structure.oebin';
            files{1}='/AG_2019-12-26_04-57-08_REST_SD_TRACK/experiment1/recording2/structure.oebin';
            files{2}='/AG_2019-12-26_04-57-08_REST_SD_TRACK/experiment2/recording1/structure.oebin';
            files{3}='/AG_2019-12-26_04-57-08_REST_SD_TRACK/experiment3/recording1/structure.oebin';
            files{4}='/AG_2019-12-26_15-09-32_POST/experiment4/recording1/structure.oebin';
            oerc=obj.loadOERFiles(fullfile(path,files));
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day03_SD';
        end
        function oerc = getRat_AG_Day04_NSD(obj)
            path='/data2/gdrive/ephys/AG/Day04_NSD';
            files{1}='/AG_2019-12-27_04-49-48_REST_NSD/Continuous_Data.openephys';
            files{2}='/AG_2019-12-27_04-49-48_NSD/Continuous_Data_2.openephys';
            files{3}='/AG_2019-12-27_04-49-48_TRACK2/Continuous_Data_4.openephys';
            files{4}='/AG_2019-12-27_14-53-37_POST/experiment1/recording1/structure.oebin';
            oerc=obj.loadOERFiles(fullfile(path,files));
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day04_NSD';
        end
        function oerc = getRat_AG_Day05_SD(obj)
            path='/data2/gdrive/ephys/AG/Day05_SD';
            files{1}='/AG_2020-01-05_05-01-42-REST_SD/experiment1/recording1/structure.oebin';
            files{2}='/AG_2020-01-05_05-01-42-SD/experiment2/recording1/structure.oebin';
            files{3}='/AG_2020-01-05_05-01-42-SD/experiment3/recording1/structure.oebin';
            files{4}='/AG_2020-01-05_05-01-42-TRACK/experiment4/recording1/structure.oebin';
            files{5}='/AG_2020-01-05_05-01-42-TRACK/experiment6/recording1/structure.oebin';
            files{6}='/AG_2020-01-05_05-01-42_POST/experiment7/recording1/structure.oebin';
            oerc=obj.loadOERFiles(fullfile(path,files));
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day05_SD';
        end
        function oerc = getRat_AG_Day06_NSD(obj)
            path='/data2/gdrive/ephys/AG/Day06_NSD';
            files{1}='/AG_2020-01-06_05-13-03_REST/experiment1/recording1/structure.oebin';
            files{2}='/AG_2020-01-06_08-19-55_NSD/experiment1/recording1/structure.oebin';
            files{3}='/AG_2020-01-06_13-14-09_TRACK/experiment1/recording1/structure.oebin';
            files{4}='/AG_2020-01-06_15-38-19_POST/experiment1/recording1/structure.oebin';
            oerc=obj.loadOERFiles(fullfile(path,files));
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day06_NSD';
        end
        function oerc = getRat_AG_testRecord(obj)
            files{1}='/data2/gdrive/ephys/AG/AG_2019-12-16_14-10-53/experiment1/recording1/structure.oebin';
            %             files{2}='/AG_2020-01-06_08-19-55_NSD/experiment1/recording1/structure.oebin';
            %             files{3}='/AG_2020-01-06_13-14-09_TRACK/experiment1/recording1/structure.oebin';
            %             files{4}='/AG_2020-01-06_15-38-19_POST/experiment1/recording1/structure.oebin';
            oerc=obj.loadOERFiles(files);
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day06_NSD';
        end
        function oerc = getRat_AF_Day01_SD(obj)
            path='/data2/gdrive/ephys/AF/Day01-SD';
            files{1}='/AF_2019-11-24_01-50-23_date1/experiment1/recording1/structure.oebin';
            files{2}='/AF_2019-11-24_01-50-23_date1/experiment2/recording1/structure.oebin';
            files{3}='/AF_2019-11-24_01-50-23_date1/experiment3/recording1/structure.oebin';
            files{4}='/AF_2019-11-24_01-50-23_date1/experiment4/recording1/structure.oebin';
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_04_AF/Day01_SD';
            oerc=obj.loadOERFiles(fullfile(path,files));
        end
        function oerc = getRat_AF_Day02_NSD(obj)
            path='/data2/gdrive/ephys/AF/Day02-NSD';
            files{1}='/AF_2019-12-04_04-47-15_day2_rest/experiment0/recording1/structure.oebin';
            files{2}='/AF_2019-12-04_08-02-16_day2_NSD/experiment1/recording1/structure.oebin';
            files{3}='/AF_2019-12-04_12-56-28_day2_track/experiment2/recording1/structure.oebin';
            files{4}='/AF_2019-12-04_14-44-12_day2_post/experiment1/recording1/structure.oebin';
            oerc=obj.loadOERFiles(fullfile(path,files));
            obj.activeWorkspaceFile=...
                '/data/EphysAnalysis/SleepDeprivationData/RAT_04_AF/Day02_NSD';
        end
    end
end