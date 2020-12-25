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
            chans=str2double( conf.channnels);
            list1=dir(fullfile(obj.BasePath,'*.xml'));
            str=DataHash(conf);
            cacheFileName=fullfile(obj.BasePath,'cache',[str '.mat']);
            [folder,~,~]=fileparts(cacheFileName);if ~isfolder(folder), mkdir(folder); end
            if ~exist(cacheFileName,'file')
                ripple=detect_swr(fullfile(list1.folder,list1.name),chans,[]...
                    ,'EVENTFILE',str2double( conf.eventfile)...
                    ,'FIGS',str2double( conf.figs)...
                    ,'swBP',str2double( conf.swbp)...
                    ,'ripBP',str2double( conf.ripbp)...
                    ,'WinSize',str2double( conf.winsize)...
                    ,'Ns_chk',str2double( conf.ns_chk)...
                    ,'thresSDswD',str2double( conf.thressdswd)...
                    ,'thresSDrip',str2double( conf.thressdrip)...
                    ,'minIsi',str2double( conf.minisi)...
                    ,'minDurSW',str2double( conf.mindursw)...
                    ,'maxDurSW',str2double( conf.maxdursw)...
                    ,'minDurRP',str2double( conf.mindurrp)...
                    ,'DEBUG',str2double( conf.debug)...
                    );
                save(cacheFileName,'ripple');
            else
                S=load(cacheFileName);
                fnames=fieldnames(S);
                ripple=S.(fnames{1});
            end
            ripple1=Ripple(ripple);
            ripple1=ripple1.setTimeIntervalCombined(obj.TimeIntervalCombined);
        end
        function ripple1 = calculateRipple(obj)
            folders={'.','..',['..',filesep,'..']};
            for ifolder=1:numel(folders)
                list=dir(fullfile(obj.BasePath,folders{ifolder},'*.conf'));
                if ~isempty(list)
                    break
                end
            end
            conf=readConf(fullfile(list.folder,list.name));
            ctd=ChannelTimeData(obj.BasePath);
            try 
                chans=str2double( conf.ripple_channelstartstop);
                chans=chans(1):chans(2);
            catch
                chans=str2double( conf.ripple_channel);
            end
            LFP=ctd.getChannelsLFP(chans);
%             FrequencyBand=[140 180];
            chan=obj.getBestChannel(LFP,str2double(conf.ripple_passband));
            list1=dir(fullfile(obj.BasePath,'*.xml'));
            str=DataHash(conf);
            cacheFileName=fullfile(obj.BasePath,'cacheripple',[str '.mat']);
            [folder,~,~]=fileparts(cacheFileName);if ~isfolder(folder), mkdir(folder); end
            if ~exist(cacheFileName,'file')
                ripple=bz_FindRipples(list1.folder,chan...
                    ,'durations',str2double(conf.ripple_durations)...
                    ,'passband',str2double(conf.ripple_passband)...
                    ,'plotType',str2double(conf.ripple_plottype)...
                    ,'show',conf.ripple_show...
                    ,'thresholds',str2double(conf.ripple_threshold)...
                    );
                save(cacheFileName,'ripple');
            else
                S=load(cacheFileName);
                fnames=fieldnames(S);
                ripple=S.(fnames{1});
            end
            ripple1=Ripple(ripple);
            ripple1=ripple1.setTimeIntervalCombined(obj.TimeIntervalCombined);
            ripple1.saveEventsNeuroscope(obj.BasePath)
        end
        function channel=getBestChannel(obj,LFP, frequencyBand)
            %[chan] = bz_GetBestRippleChan(lfp)
            %eventually this will detect which lfp channel has the highest SNR for the
            % ripple componenent of SPWR events....
            
            data=ft_preproc_bandpassfilter(LFP.data,LFP.sampleRate,frequencyBand);
            
            for i=1:length(LFP.channels)
                pow = fastrms(data(i,:),15);
                mRipple(i) = mean(pow);
                meRipple(i) = median(pow);
                mmRippleRatio(i) = mRipple(i)./meRipple(i);
            end
            mmRippleRatio(mRipple<1) = 0;
            mmRippleRatio(meRipple<1) = 0;
            
            [~, loc] = max(mmRippleRatio);
            channel = LFP.channels(loc);
            
        end
    end
end

