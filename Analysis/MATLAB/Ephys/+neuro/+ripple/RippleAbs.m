classdef RippleAbs
    %RIPPLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimeIntervalCombined
        DetectorInfo
    end
    methods (Abstract)
        getPeakTimes(obj)
        getStartStopTimes(obj)
        getRipMax(obj)
        getSwMax(obj)
    end
    methods

        
        function outputArg = plotScatterHoursInXAxes(obj)
            ticd=obj.TimeIntervalCombined;
            peaktimestamps=obj.getPeakTimes*ticd.getSampleRate;
            peakTimeStampsAdjusted=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestamps);
            peakTimesAdjusted=peakTimeStampsAdjusted/ticd.getSampleRate;
            peakripmax=obj.RipMax(:,1);
            s=scatter(hours(seconds(peakTimesAdjusted)),peakripmax...
                ,'Marker','.','MarkerFaceAlpha',.7,'MarkerEdgeAlpha',.7,...
                'SizeData',50);
            
        end
        function outputArg = plotScatterAbsoluteTimeInXAxes(obj)
            ticd=obj.TimeIntervalCombined;
            peaktimestamps=obj.getPeakTimes*ticd.getSampleRate;
            peakTimeStampsAdjusted=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestamps);
            peakTimesAdjusted=peakTimeStampsAdjusted/ticd.getSampleRate;
            peakripmax=obj.RipMax(:,1);
            s=scatter(seconds(peakTimesAdjusted)+ticd.getStartTime,peakripmax...
                ,'Marker','.','MarkerFaceAlpha',.7,'MarkerEdgeAlpha',.7,...
                'SizeData',50);
            
        end
        function [p2] = plotHistCount(obj, TimeBinsInSec)
            if ~exist('TimeBinsInSec','var')
                TimeBinsInSec=30;
            end
            ticd=obj.TimeIntervalCombined;
            peaktimestamps=obj.getPeakTimes*ticd.getSampleRate;
            peakTimeStampsAdjusted=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestamps);
            peakTimesAdjusted=peakTimeStampsAdjusted/ticd.getSampleRate;
            [N,edges]=histcounts(peakTimesAdjusted,1:TimeBinsInSec:max(peakTimesAdjusted));
            t=hours(seconds(edges(1:(numel(edges)-1))+15));
            t1=linspace(min(t),max(t),numel(t)*10);
            N=N/TimeBinsInSec;
            N=interp1(t,N,t1,'spline','extrap');
            p2=plot(t1,N,'LineWidth',1);
        end
        
        function [ripples, y]=getRipplesTimesInWindow(obj,toi)
            
            ticd=obj.TimeIntervalCombined;
            if isduration(toi)
                st=ticd.getStartTime;
                toi1=datetime(st.Year,st.Month,st.Day)+toi;
            else
                toi1=toi;
            end
            samples=ticd.getSampleFor(toi1);
            secs=samples/ticd.getSampleRate;
            peaktimes=obj.getPeakTimes;
            idx=peaktimes>=secs(1)&peaktimes<=secs(2);
            pt1=peaktimes(idx);
            ripmax=obj.getRipMax;
            y=ripmax(idx);
            if ~isempty(pt1)
                sample=pt1*ticd.getSampleRate;
                ripples=ticd.getRealTimeFor(sample);
            else
                ripples=[];
            end
            
        end
        function obj=getWindow(obj,window)
            ticd=obj.TimeIntervalCombined;
            peaktimes=obj.PeakTimes;
            start=peaktimes.start;
            stop=peaktimes.stop;
            
            windowdt=window+ticd.getDate;
            
            blockInSec=ticd.getSampleFor(windowdt)/ticd.getSampleRate;
            if isnan(blockInSec(1))
                blockInSec(1)=1;
                windowdt(1)=ticd.getStartTime;
            end
            if isnan(blockInSec(2))
                blockInSec(2)=ticd.getNumberOfPoints/ticd.getSampleRate;
                windowdt(2)=ticd.getEndTime;
            end
            ticd_new=ticd.getTimeIntervalForTimes(windowdt);
            idxstart=start>blockInSec(1)&start<blockInSec(2);
            idxstop=stop>blockInSec(1)&stop<blockInSec(2);
            idx=idxstart|idxstop;
            peaktimes.start=peaktimes.start(idx);
            peaktimes.stop=peaktimes.stop(idx);
            peaktimes.peak=peaktimes.peak(idx)-blockInSec(1);
            if ~isempty(peaktimes.start)
                if peaktimes.start(1)<blockInSec(1)
                    peaktimes.start(1)=blockInSec(1);
                end
                if peaktimes.stop(end)>blockInSec(2)
                    peaktimes.stop(end)=blockInSec(2);
                end
            end
            peaktimes.start=peaktimes.start-blockInSec(1);
            peaktimes.stop=peaktimes.stop-blockInSec(1);
            obj.PeakTimes=peaktimes;
            obj.SwMax=obj.SwMax(idx);
            obj.RipMax=obj.RipMax(idx);
            obj.TimeIntervalCombined=ticd_new;
        end
        function []= saveEventsNeuroscope(obj,pathname)
            tokens=split(pathname,filesep);
            filename=tokens{end};
            fid = fopen(sprintf('%s%s%s.R%02d.evt',pathname,filesep,filename,1),'w');
            
            % convert detections to milliseconds
            peakTimes= obj.getPeakTimes*1000;
            startStopTimes= obj.getStartStopTimes*1000;
            fprintf(1,'Writing event file ...\n');
            for ii = 1:size(peakTimes,1)
                fprintf(fid,'%9.1f\tstart\n',startStopTimes(ii,1));
                fprintf(fid,'%9.1f\tpeak\n',peakTimes(ii));
                fprintf(fid,'%9.1f\tstop\n',startStopTimes(ii,2));
            end
            fclose(fid);
        end
        function obj = setTimeIntervalCombined(obj,ticd)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.TimeIntervalCombined=ticd;
        end
        function objnew= plus(obj,newRiple)
            pt_base=obj.getPeakTimes;
            rt_base=obj.getStartStopTimes;
            rp_base=obj.getRipMax;
            swp_base=obj.getSwMax;
            pt_new=newRiple.getPeakTimes;
            rt_new=newRiple.getStartStopTimes;
            rp_new=newRiple.getRipMax;
            swp_new=newRiple.getSwMax;
            rt_count=0;
            ripple.detectorinfo=obj.DetectorInfo;
            for irip=1:size(rt_base,1)
                art_base=rt_base(irip,:);
                base.start=art_base(1);
                base.stop=art_base(2);
                base.peak=pt_base(irip);
                base.power=rp_base(irip);
                base.swpower=swp_base(irip);
                base.duration=base.stop-base.start;

                new_start_is_in_old_ripple=(rt_new(:,1)>base.start & rt_new(:,1)<base.stop);
                new_stop_is_in_old_ripple=(rt_new(:,2)>base.start & rt_new(:,2)<base.stop);
                idx=new_start_is_in_old_ripple|new_stop_is_in_old_ripple;
                if sum(idx)>1 
                    x=find(idx);
                    idx1=false(size(idx));
                    idx1(x(1))=true; 
                    idx=idx1;
                end
                rippleHasNoOverlap=~sum(idx);
                if rippleHasNoOverlap
                    rt_count=rt_count+1;
                    ripple.timestamps(rt_count,1)=base.start;
                    ripple.peaktimes(rt_count,1)=base.peak;
                    ripple.timestamps(rt_count,2)=base.stop;
                    ripple.RipMax(rt_count,1)=base.power;
                    ripple.SwMax(rt_count,1)=base.swpower;
                    
                else
                    new.start=rt_new(idx,1);
                    new.stop=rt_new(idx,2);
                    rt_new(idx,:)=[];
                    new.peak=pt_new(idx);pt_new(idx)=[];
                    new.power=rp_new(idx);rp_new(idx)=[];
                    new.swpower=swp_new(idx);swp_new(idx)=[];
                    new.duration=new.stop-new.start;
                    %% Check if one of them is SWR
                    ripplesAreInSametype=~xor( isnan(base.swpower), isnan(new.swpower));
                    if ripplesAreInSametype
                        if new.power<base.power
                            selectBase=true;
                        else
                            selectBase=false;
                        end
                    else
                        baseIsSW=~isnan(base.swpower);
                        if baseIsSW
                            selectBase=true;
                        else
                            selectBase=false;
                        end
                    end
                    
                    
                    if selectBase
                        rt_count=rt_count+1;
                        ripple.timestamps(rt_count,1)=base.start;
                        ripple.peaktimes(rt_count,1)=base.peak;
                        ripple.timestamps(rt_count,2)=base.stop;
                        ripple.RipMax(rt_count,1)=base.power;
                        ripple.SwMax(rt_count,1)=base.swpower;
                    else
                        rt_count=rt_count+1;
                        ripple.timestamps(rt_count,1)=new.start;
                        ripple.peaktimes(rt_count,1)=new.peak;
                        ripple.timestamps(rt_count,2)=new.stop;
                        ripple.RipMax(rt_count,1)=new.power;
                        ripple.SwMax(rt_count,1)=new.swpower;
                    end
           
                end
            end
            [ripple.peaktimes, idx]=sort([ripple.peaktimes; pt_new],1);
            ripple.timestamps=[ripple.timestamps; rt_new];
            ripple.timestamps=ripple.timestamps(idx,:);
            ripple.RipMax=[ripple.RipMax; rp_new];
            ripple.RipMax=ripple.RipMax(idx);
            ripple.SwMax=[ripple.SwMax; swp_new];
            ripple.SwMax=ripple.SwMax(idx);
            
            objnew=neuro.ripple.SWRipple(ripple);
            objnew=objnew.setTimeIntervalCombined(obj.TimeIntervalCombined);
            objnew=objnew.mergeOverlappingRipples;
        end
        
        function obj=mergeOverlappingRipples(obj)
                    
            firstPass=[obj.PeakTimes.start obj.PeakTimes.stop];
            secondPassRipple=[];
            secondPassPeak=[];
            secondPassPower=[];
            secondPassSw=[];
            theRipple = firstPass(1,:);
            thePower=obj.RipMax(1);
            thePeakTime=obj.PeakTimes.peak(1);
            theSw=obj.SwMax(1);
            for i = 2:size(firstPass,1)
                if firstPass(i,1) - theRipple(2) < 0
                    % Merge
                    theRipple = [theRipple(1) firstPass(i,2)];
                    if thePower<obj.RipMax(i)
                        thePower=obj.RipMax(i);
                        thePeakTime=obj.PeakTimes.peak(i);
                        theSw=obj.SwMax(i);
                    end
                else
                    secondPassRipple = [secondPassRipple ; theRipple];
                    secondPassPeak = [secondPassPeak ; thePeakTime];
                    secondPassPower = [secondPassPower ; thePower];
                    secondPassSw = [secondPassSw ; theSw];
                    theRipple = firstPass(i,:);
                    thePower=obj.RipMax(i);
                    thePeakTime=obj.PeakTimes.peak(i);
                    theSw=obj.SwMax(i);
                end
            end
            obj.PeakTimes.start=secondPassRipple(:,1);
            obj.PeakTimes.stop=secondPassRipple(:,2);
            obj.PeakTimes.peak=secondPassPeak;
            obj.RipMax=secondPassPower;
            obj.SwMax=secondPassSw;
            
        end
    end
end

