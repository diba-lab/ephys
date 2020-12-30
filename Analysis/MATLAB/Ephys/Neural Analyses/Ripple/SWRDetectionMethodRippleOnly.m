classdef SWRDetectionMethodRippleOnly < SWRDetectionMethod
    %SWRDETECTIONMETHODRIPPLEONLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SWRDetectionMethodRippleOnly(basepath)
            obj@SWRDetectionMethod(basepath)
        end
        
        function ripple1 = execute(obj,varargin)
            conf=obj.Configuration;
            ctd=ChannelTimeData(obj.BasePath);
            if nargin>1
                chans=varargin{1};
            else
                chans=str2double( conf.ripple_channel);
            end
            LFP=ctd.getChannelsLFP(chans);
            passband=str2double(conf.ripple_passband);
            paramFile=fullfile(obj.BasePath,'Parameters','RippleDetection.xml');
            [folder,~,~]=fileparts(paramFile); if ~isfolder(folder), mkdir(folder);end
            chasStr=genvarname(['ch' num2str(chans','_%d')]);
            try
                Ripple1=readstruct(paramFile);
            catch
                Ripple1.BestChannel.(chasStr)=nan;
                writestruct(Ripple1,paramFile);
                Ripple1=readstruct(paramFile);
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
            conf.chan=chan;
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
        end
    end
end

