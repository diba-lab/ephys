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
            
            obj.Probe=neuro.probe.Probe(obj.BasePath);
            obj.TimeIntervalCombined=neuro.time.TimeIntervalCombined(obj.BasePath);
        end
        function ripple1 = calculateSWR(obj)
            import neuro.ripple.*
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
                    method=neuro.ripple.SWRDetectionMethodRippleOnly(obj.BasePath);
                case 2
                    method=neuro.ripple.SWRDetectionMethodSWR(obj.BasePath);
                case 3
                    method=neuro.ripple.SWRDetectionMethodCombined(obj.BasePath);
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
            import buzcode.sleepDetection.*
            logger=logging.Logger.getLogger;
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
                    logger.warning('No SW Channels set.')
                end
                try
                    if ~(isempty(params.Channels.BestTheta)||strcmp(params.Channels.BestTheta,""))
                        varargin={varargin{:},'ThetaChannels',params.Channels.BestTheta};
                    else
                        varargin={varargin{:},'ThetaChannels',params.Channels.ThetaChannels};
                    end
                catch
                    logger.warning('No Theta Channels set.')                    
                end
                try
                    varargin={varargin{:},'EMGChannels',params.Channels.EMGChannel};
                catch
                    logger.warning('No EMG Channels set.')                    
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
                    logger.warning('No Ignore Times set.')
                end
                varargin1=varargin(2:end);
                logger.info(['SleepScoreMaster is callled with the following parameters: ', strjoin(varargin1)]);

                SleepScoreMaster(obj.BasePath,varargin1{:});
                sdd=StateDetectionData(obj.BasePath);
            end
        end
        
        function obj=setBadIntervals(obj,bad)
            obj.BadIntervals=bad;
        end
    end
end

