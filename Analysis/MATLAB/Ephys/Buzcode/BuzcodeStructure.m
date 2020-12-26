classdef BuzcodeStructure
    %BUZCODESTRUCTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        BasePath
        TimeIntervalCombined
        Probe
    end
    
    methods
        function obj = BuzcodeStructure(filepath)
            %Select from no input
            if ~exist('filepath','var')
                defpath='/data/EphysAnalysis/SleepDeprivationData/';
                defpath1={'*.eeg;*.lfp;*.dat;*.mat','Binary Record Files (*.eeg,*.lfp,*.dat)'};
                title='Select basepath';
                [~,filepath,~] = uigetfile(defpath1, title, defpath,'MultiSelect', 'off');
            end
            if isfolder(filepath)
                folder=filepath;
            else
                [folder,~,~]=fileparts(filepath);
            end
            exts={'.lfp','.eeg','.dat'};
            for iext=1:numel(exts)
                theext=exts{iext};
                thefile=dir(fullfile(folder,['*' theext]));
                if numel(thefile)>0
                    break
                end
            end
            obj.BasePath=filepath;
            
            try
                list=dir(fullfile(obj.BasePath,'*Probe*'));
                obj.Probe=Probe(fullfile(list.folder,list.name));
            catch
                fprintf('No Probe File at: %s',obj.BasePath);
            end
            try
                list=dir(fullfile(obj.BasePath,'*TimeInterval*'));
                S=load(fullfile(list.folder,list.name));
                fnames=fieldnames(S);
                obj.TimeIntervalCombined=S.(fnames{1});
            catch
                fprintf('No TimeIntervalCombined File at: %s',obj.BasePath);
            end
        end
        function ripple1 = calculateSWR(obj)
            folders={'.','..',['..',filesep,'..']};
            for ifolder=1:numel(folders)
                list=dir(fullfile(obj.BasePath,folders{ifolder},'*.conf'));
                if ~isempty(list)
                    break
                end
            end
            conf=readConf(fullfile(list.folder,list.name));
            switch str2double(conf.detectiontype)
                case 1
                    method=SWRDetectionMethodRippleOnly(obj.BasePath);
                case 2
                    method=SWRDetectionMethodSWR(obj.BasePath);
                case 3
                    method=SWRDetectionMethodCombined(obj.BasePath);
                otherwise
                    error('Incorrect Detection Type. Should be 1,2, or 3.')
            end
            ripple1=method.execute;
            ripple1=ripple1.setTimeIntervalCombined(obj.TimeIntervalCombined);
        end
        function [] = calculateRipple(obj)
            warning('Depricated! Use calculateSWR() and change configure.conf file. Set detection type=1.')
        end        
    end
end

