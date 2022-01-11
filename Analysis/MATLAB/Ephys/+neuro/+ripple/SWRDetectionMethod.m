classdef (Abstract) SWRDetectionMethod
    %SWRDETECTIONMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        BasePath
        Configuration
    end
    methods (Abstract)
        execute(obj)
    end
    methods
        function obj=SWRDetectionMethod(basepath)
            folders={'.','..',['..',filesep,'..']};
            for ifolder=1:numel(folders)
                list=dir(fullfile(basepath,folders{ifolder},'SWRconfigure.conf'));
                if ~isempty(list)
                    break
                end
            end
            obj.Configuration=readConf(fullfile(list.folder,list.name));
            obj.BasePath=basepath;
        end
        function channel=getBestRippleChannel(obj, LFP, frequencyBand)
            %[chan] = bz_GetBestRippleChan(lfp)
            %eventually this will detect which lfp channel has the highest SNR for the
            % ripple componenent of SPWR events....
            ft_defaults
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
