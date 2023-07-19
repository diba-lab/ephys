classdef SWRDetectionMethodRippleOnly < neuro.ripple.SWRDetectionMethod
    %SWRDETECTIONMETHODRIPPLEONLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Epochs
    end
    
    methods
        function obj = SWRDetectionMethodRippleOnly(basepath)
            obj@neuro.ripple.SWRDetectionMethod(basepath)
            conf=obj.Configuration;
            if isfield(conf,'bad_file')
                bad=fullfile(basepath, conf.bad_file);
                ticd=neuro.basic.ChannelTimeDataHard(obj.BasePath).getTimeIntervalCombined;
                dur=seconds(ticd.getNumberOfPoints/ticd.getSampleRate);
                arts_rev=neuro.time.TimeWindowsDuration(readtable(bad)).getReverse(dur);
                obj.Epochs=table2array( arts_rev.getTimeTable);
            end
        end
        
        function ripple1 = execute(obj,varargin)
            conf=obj.Configuration;
            ctd=neuro.basic.ChannelTimeDataHard(obj.BasePath);
            if nargin > 1
                chans=varargin{1};
            else
                chans=str2double( conf.ripple_channel);
            end
            passband=str2double(conf.ripple_passband);
            paramFile=fullfile(obj.BasePath,'Parameters','RippleDetection.xml');
            [folder, ~, ~]=fileparts(paramFile); if ~isfolder(folder), mkdir(folder);end
            if size(chans,1)>1, chans=chans';end
            chasStr=matlab.lang.makeValidName(['ch' num2str(chans,'_%d')]);
            try
                Ripple1=readstruct(paramFile);
            catch
                Ripple1.BestChannel.(chasStr)=nan;
                writestruct(Ripple1,paramFile);
                Ripple1=readstruct(paramFile);
            end
            if ~isfield(Ripple1.BestChannel, chasStr)||~isnumeric(Ripple1.BestChannel.(chasStr))
                LFP=ctd.getChannelsLFP(chans);
            end
            if ~isfield(Ripple1.BestChannel, chasStr)
                bestchan=obj.getBestRippleChannel(LFP,passband);
                    Ripple1.BestChannel.(chasStr)=bestchan;
            else
                if ~isnumeric(Ripple1.BestChannel.(chasStr))
                    bestchan=obj.getBestRippleChannel(LFP,passband);
                    Ripple1.BestChannel.(chasStr)=bestchan;
                end
            end
            writestruct(Ripple1,paramFile);
            
            chan=Ripple1.BestChannel.(chasStr);
            list1=dir(fullfile(obj.BasePath,'*.xml'));
            if numel(list1)>1
                list1=list1(1);
            end
            conf.chan=chan;
            str=DataHash(conf);
            cacheFileName=fullfile(obj.BasePath,'cacheripple',['ro_' num2str(chan) '_' str '.mat']);
            [folder,~,~]=fileparts(cacheFileName);if ~isfolder(folder), mkdir(folder); end
            if ~exist(cacheFileName,'file')
                %% ~~~Convert the Channels into Neuroscope~~~
                ripple=bz_FindRipples(list1.folder,(chan-1)...
                    ,'durations',str2double(conf.ripple_durations)...
                    ,'passband',str2double(conf.ripple_passband)...
                    ,'plotType',str2double(conf.ripple_plottype)...
                    ,'show',conf.ripple_show...
                    ,'thresholds',str2double(conf.ripple_threshold)...
                    ,'EMGThresh',str2double(conf.ripple_emgthreshold)...
                    ,'restrict',obj.Epochs...
                    );
                save(cacheFileName,'ripple');
            else
                S=load(cacheFileName);
                fnames=fieldnames(S);
                ripple=S.(fnames{1});
            end
            ripple1=neuro.ripple.Ripple(ripple);
            ripple1.DetectorInfo.BasePath=obj.BasePath;
        end
    end
end

