classdef SWRDetectionMethodSWR < SWRDetectionMethod
    %SWRDETECTIONMETHODRIPPLEONLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SWRDetectionMethodSWR(basepath)
            %SWRDETECTIONMETHODRIPPLEONLY Construct an instance of this class
            %   Detailed explanation goes here
            
            obj@SWRDetectionMethod(basepath)
        end
        
        function ripple1 = execute(obj,varargin)
            conf=obj.Configuration;
            if nargin>1
                chans=varargin{1};
            else
                chans=str2double( conf.ripple_channel);
            end
            list1=dir(fullfile(obj.BasePath,'*.xml'));
            conf.chans=chans;
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
            ripple1=SWRipple(ripple);
        end
        function objnew= plus(obj,newRiple)
            pt_base=obj.getPeakTimes;
            rt_base=obj.getStartStopTimes;
            rp_base=obj.getRipplePower;
            pt_new=newRiple.getPeakTimes;
            rt_new=newRiple.getStartStopTimes;
            rp_new=newRiple.getRipplePower;
            rt_count=0;
            ripple.detectorinfo=obj.DetectorInfo;
            for irip=1:size(rt_base,1)
                art_base=rt_base(irip,:);
                base.start=art_base(1);
                base.stop=art_base(2);
                base.peak=pt_base(irip);
                base.power=rp_base(irip);
                base.duration=base.stop-base.start;

                new_start_is_in_old_ripple=(rt_new(:,1)>base.start & rt_new(:,1)<base.stop);
                new_stop_is_in_old_ripple=(rt_new(:,2)>base.start & rt_new(:,2)<base.stop);
                idx=new_start_is_in_old_ripple|new_stop_is_in_old_ripple;
                rippleHasNoOverlap=~sum(idx);
                if rippleHasNoOverlap
                    rt_count=rt_count+1;
                    ripple.timestamps(rt_count,1)=base.start;
                    ripple.peaks(rt_count,1)=base.peak;
                    ripple.timestamps(rt_count,2)=base.stop;
                    ripple.peakNormedPower(rt_count,1)=base.power;
                    
                else
                    new.start=rt_new(idx,1);
                    new.stop=rt_new(idx,2);
                    rt_new(idx,:)=[];
                    new.peak=pt_new(idx);pt_new(idx)=[];
                    new.power=rp_new(idx);rp_new(idx)=[];
                    new.duration=new.stop-new.start;
                    if new.power<base.power
                        rt_count=rt_count+1;
                        ripple.timestamps(rt_count,1)=base.start;
                        ripple.peaks(rt_count,1)=base.peak;
                        ripple.timestamps(rt_count,2)=base.stop;
                        ripple.peakNormedPower(rt_count,1)=base.power;
                    else
                        rt_count=rt_count+1;
                        ripple.timestamps(rt_count,1)=new.start;
                        ripple.peaks(rt_count,1)=new.peak;
                        ripple.timestamps(rt_count,2)=new.stop;
                        ripple.peakNormedPower(rt_count,1)=new.power;
                    end
                        
                end
            end
            [ripple.peaks, idx]=sort([ripple.peaks; pt_new],1);
            ripple.timestamps=[ripple.timestamps; rt_new];
            ripple.timestamps=ripple.timestamps(idx,:);
            ripple.peakNormedPower=[ripple.peakNormedPower; rp_new];
            ripple.peakNormedPower=ripple.peakNormedPower(idx);
            
            objnew=Ripple(ripple);
            objnew=objnew.setTimeIntervalCombined(obj.TimeIntervalCombined);
        end
        
    end
end

