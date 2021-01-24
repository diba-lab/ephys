classdef BuzcodeStructure
    %BUZCODESTRUCTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        BasePath
        TimeIntervalCombined
        BadIntervals
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
                obj.TimeIntervalCombined=TimeIntervalCombined(fullfile(list.folder,list.name));
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
        function sdd = detectStates(obj,params)
            try
                sdd=StateDetectionData(obj.BasePath);
            catch
                
                if params.Overwrite, overwrite=true; else, overwrite=false;end
                varargin=cell(1,1);
                try
                    if ~(isempty(params.Channels.BestSW)||strcmp(params.Channels.BestSW,""))
                        varargin={varargin{:}, 'SWChannels', params.Channels.BestSW};
                    else
                        varargin={varargin{:}, 'SWChannels', params.Channels.SWChannels};
                    end
                catch
                end
                try
                    if ~(isempty(params.Channels.BestTheta)||strcmp(params.Channels.BestTheta,""))
                        varargin={varargin{:},'ThetaChannels',params.Channels.BestTheta};
                    else
                        varargin={varargin{:},'ThetaChannels',params.Channels.ThetaChannels};
                    end
                catch
                end
                try
                    varargin={varargin{:},'EMGChannels',params.Channels.EMGChannel};
                catch
                end
                try varargin={varargin{:},'overwrite',overwrite};catch; end
                try
                    bad=struct2table( params.bad.Time);
                    sampleRate=obj.TimeIntervalCombined.getSampleRate;
                    start=obj.TimeIntervalCombined.getSampleFor(bad.Start)/sampleRate;
                    stop=obj.TimeIntervalCombined.getSampleFor(bad.Stop)/sampleRate;
                    bad1(:,1)=start;
                    bad1(:,2)=stop;
                    varargin={varargin{:},'ignoretime',bad1};
                catch
                end
                varargin1=varargin(2:end);
                SleepScoreMaster(obj.BasePath,varargin1{:});
                sdd=StateDetectionData(obj.BasePath);
            end
        end
        
        function obj=setBadIntervals(obj,bad)
            obj.BadIntervals=bad;
        end
    end
end

