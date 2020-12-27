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
            peaktimestamps=obj.PeakTimes*ticd.getSampleRate;
            peakTimeStampsAdjusted=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestamps);
            peakTimesAdjusted=peakTimeStampsAdjusted/ticd.getSampleRate;
            peakripmax=obj.RipMax(:,1);
            s=scatter(hours(seconds(peakTimesAdjusted)),peakripmax...
                ,'Marker','.','MarkerFaceAlpha',.7,'MarkerEdgeAlpha',.7,...
                'SizeData',50);
            
        end
        function outputArg = plotScatterAbsoluteTimeInXAxes(obj)
            ticd=obj.TimeIntervalCombined;
            peaktimestamps=obj.PeakTimes*ticd.getSampleRate;
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
            peaktimestamps=obj.PeakTimes*ticd.getSampleRate;
            peakTimeStampsAdjusted=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestamps);
            peakTimesAdjusted=peakTimeStampsAdjusted/ticd.getSampleRate;
            [N,edges]=histcounts(peakTimesAdjusted,1:TimeBinsInSec:max(peakTimesAdjusted));
            t=hours(seconds(edges(1:(numel(edges)-1))+15));
            t1=linspace(min(t),max(t),numel(t)*10);
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
        function obj=getRipplesInWindow(obj,toi)
%             
%             ticd=obj.TimeIntervalCombined;
%             if isduration(toi)
%                 st=ticd.getStartTime;
%                 toi1=datetime(st.Year,st.Month,st.Day)+toi;
%             else
%                 toi1=toi;
%             end
%             samples=ticd.getSampleFor(toi1);
%             secs=samples/ticd.getSampleRate;
%             idx=obj.PeakTimes>=secs(1)&obj.PeakTimes<=secs(2);
%             ticd_new=obj.TimeIntervalCombined.getTimeIntervalForTimes(toi(1),toi(2));
%             dt=ticd_new.getStartTime-ticd.getStartTime;
% 
%             obj.PeakTimes=obj.PeakTimes(idx);
%             obj.PeakTimes-seconds(dt)
%             obj.RipMax=obj.RipMax(idx,:);
%             obj.SwMax=obj.SwMax(idx,:);
%             obj.TimeStamps=obj.TimeStamps(idx,:);
%             obj.TimeIntervalCombined
        end
        function []= saveEventsNeuroscope(obj,pathname)
            rippleFiles = dir(fullfile(pathname,'*.R*.evt'));
            if isempty(rippleFiles)
                fileN = 1;
            else
                %set file index to next available value\
                pat = '.R[0-9].';
                fileN = 0;
                for ii = 1:length(rippleFiles)
                    token  = regexp(rippleFiles(ii).name,pat);
                    val    = str2double(rippleFiles(ii).name(token+2:token+4));
                    fileN  = max([fileN val]);
                end
                fileN = fileN + 1;
            end
            tokens=tokenize(pathname,filesep);
            filename=tokens{end};
            fid = fopen(sprintf('%s%s%s.R%02d.evt',pathname,filesep,filename,fileN),'w');
            
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
                    if new.power<base.power
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
                        
            objnew=SWRipple(ripple);
            objnew=objnew.setTimeIntervalCombined(obj.TimeIntervalCombined);
        end
        
    end
end

