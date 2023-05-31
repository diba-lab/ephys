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
                obj.BadIntervals=neuro.time.TimeWindowsDuration(obj.BasePath);
            catch
                logging.Logger.getLogger.warning( ...
                    'Could not find an evt file in %s',obj.BasePath);
            end
            obj.Probe=neuro.probe.Probe(obj.BasePath);
            obj.TimeIntervalCombined=neuro.time.TimeIntervalCombined(obj.BasePath);
        end
        function ripple1 = calculateSWR(obj)
            import neuro.ripple.*
            folders={'.','..',['..',filesep,'..']};
            for ifolder=1:numel(folders)
                list=dir(fullfile(obj.BasePath,folders{ifolder},'SWRconfigure.conf'));
                if ~isempty(list)
                    break
                end
            end
            if ~isempty(list)
                try
                    conf=readConf(fullfile(list.folder,list.name));
                catch
                end
            else
                for ifolder=1:numel(folders)
                list=dir(fullfile(obj.BasePath,folders{ifolder},'*SWR.conf.xml'));
                if ~isempty(list)
                    break
                end
                if ~isempty(list)
                    conf=readstruct(fullfile(list.folder,list.name));
                end
            end

            end
            switch str2double(conf.detectiontype)
                case 1
                    method=neuro.ripple.SWRDetectionMethodRippleOnly(obj.BasePath);
                case 2
                    method=neuro.ripple.SWRDetectionMethodSWR(obj.BasePath);
                case 3
                    method=neuro.ripple.SWRDetectionMethodCombined(obj.BasePath);
                otherwise
                    error('Incorrect Detection Type. Should be 1, 2, or 3.')
            end
            ripple1=method.execute();
            ripple1=ripple1.setTimeIntervalCombined(obj.TimeIntervalCombined);
        end
        function sdd = recalculateStates(obj,dur)
            import buzcode.sleepDetection.*
            logger=logging.Logger.getLogger;
            time=obj.TimeIntervalCombined;
            dur1=seconds(time.getSampleFor(dur)/time.getSampleRate);
            sdd=buzcode.sleepDetection.StateDetectionData(obj.BasePath);


            SleepScoreMaster(obj.BasePath,varargin1{:});
            sdd=buzcode.sleepDetection.StateDetectionData(obj.BasePath);
        end
        function sdd = detectStates(obj,params)
            import buzcode.sleepDetection.*
            logger=logging.Logger.getLogger;
            try
                sdd=buzcode.sleepDetection.StateDetectionData(obj.BasePath);
            catch
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
                try varargin={varargin{:},'overwrite',logical(params.Overwrite)};catch; end
                try varargin={varargin{:},'NotchHVS',logical(params.HVSFilter)};catch; end
                try
                    varargin={varargin{:},'ignoretime',params.bad};
                catch
                    try
                        varargin={varargin{:},'ignoretime',obj.BadIntervals.getArrayForBuzcode};
                    catch
                        logger.warning('No bad intervals found.')
                    end
                    logger.warning('No Ignore Times set.')
                end
                varargin0=varargin(2:2:end);
                varargin1=varargin(2:end);
                joinedstr=join(varargin0,', ');
                logger.info(sprintf('SleepScoreMaster is callled with the following parameters: %s', ...
                    joinedstr{:} ...
                    ));
                
                SleepScoreMaster(obj.BasePath,varargin1{:});
                sdd=buzcode.sleepDetection.StateDetectionData(obj.BasePath);
            end
        end
        
        function obj=setBadIntervals(obj,bad)
            obj.BadIntervals=bad;
        end
    end
end

