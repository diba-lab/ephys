classdef TimeInterval < neuro.time.TimeIntervalAbstract
    %INTERVAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SampleRate
        StartTime
        NumberOfPoints
    end
    
    methods
        function obj = TimeInterval(startTime, sampleRate, numberOfPoints)
            %INTERVAL Construct an instance of this class
            %   Detailed explanation goes here
            obj.SampleRate = sampleRate;
            obj.StartTime=startTime;
            obj.StartTime.Format='uuuu-MM-dd HH:mm:ss.SSS';
            
            obj.NumberOfPoints=numberOfPoints;
%             obj.Format='dd-MMM-uuuu HH:mm:ss.SSS';
            obj.Format='HH:mm:ss.SSS';
        end
        
        function []=print(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            fprintf('%s',obj.tostring);
        end
        function str=tostring(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            date=datestr(obj.getDate,1);
            st=datestr( obj.getStartTime,'HH:MM:SS.FFF');
            en=datestr(obj.getEndTime,'HH:MM:SS.FFF');
            dur=obj.getEndTime-obj.getStartTime;
            dur1=datestr(dur,'HH:MM:SS.FFF');
            sf=obj.getSampleRate;
            np=obj.getNumberOfPoints;
            jf=java.text.DecimalFormat; % comma for thousands, three decimal places
            np1= char(jf.format(np)); % omit "char" if you want a string out
            
            str=sprintf('\t%s \t%s - %s\t<%s>\t<%s (%dHz)> \n',date,st,en,dur1,np1,sf);
        end
        function S=getStruct(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            S.StartTime=obj.StartTime;
            S.NumberOfPoints=obj.NumberOfPoints;
            S.SampleRate=obj.SampleRate;
        end
        function timeInterval=getTimeIntervalForSamples(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if nargin>2
                startSample=varargin{1};
                endSample=varargin{2};
            else
                wind=varargin{1};
                startSample=wind(1);
                endSample=wind(2);
            end
            
            if startSample>obj.NumberOfPoints || endSample<1
                timeInterval=[];
                return
            elseif startSample>0 && startSample<=obj.NumberOfPoints
                obj.StartTime=obj.getRealTimeFor(startSample);
                if endSample<=obj.NumberOfPoints
                    obj.NumberOfPoints=endSample-startSample+1;
                else
                    obj.NumberOfPoints=obj.NumberOfPoints-startSample+1;
                end
            else %start sample is smaller than 0 no change in start time
                if endSample<obj.NumberOfPoints
                    obj.NumberOfPoints=endSample;
                else
                    %no change in numpoints
                end

                % no change in start time
            end

            timeInterval=obj;
        end
        function timeIntervals=getTimeIntervalForTimes(obj,windows)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isa(windows,'neuro.time.ZeitgeberTime')
                windows=windows.getAbsoluteTime;
            elseif isduration(windows)
                windows=obj.convertDurationToDatetime(windows);
            end
            for iwin=1:size(windows,1)
                window=windows(iwin,:);
                windowsSmplescl=obj.getSampleForClosest(window);
                timeIntervals(iwin,:)=obj.getTimeIntervalForSamples( ...
                    windowsSmplescl(1),windowsSmplescl(2)); %#ok<AGROW>
            end
        end

        function time=getRealTimeFor(obj,samples)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            idx=samples>0 & samples<=obj.NumberOfPoints;
            if numel(idx)>0
                for icol=1:size(idx,2)
                    validsamples(:,icol)=samples(idx(:,icol),icol);
                end
                time=obj.StartTime+seconds(double((validsamples-1))/obj.SampleRate);
                time.Format=obj.Format;
            else
                time=[];
            end
            
            if sum(~idx)
                warning('Sample is not in the TimeInterval -- should be between\n\t%d -- %d\n'...
                    ,1,obj.NumberOfPoints);
            end
        end
        function samples=getSampleFor(obj,times)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            samples=nan(size(times));
            st=obj.StartTime;
            en=obj.getEndTime;
            for i=1:numel(times)
                time=times(i);
                if time>=st && time<=en
                    samples(i)=round(seconds(time-obj.StartTime)* ...
                        obj.SampleRate)+1;
                    if samples(i)<1
                        samples(i)=1;
                    end
                end
            end
        end
        function samples=getSampleForClosest(obj,times)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=obj.getDatetime(times);
            
            samples=nan(size(times));
            
            theTimeInterval=obj;
            ends(1)=theTimeInterval.getStartTime;
            ends(2)=theTimeInterval.getEndTime;
            idx=times>=theTimeInterval.StartTime & ...
                times<=theTimeInterval.getEndTime;
            samples(idx)=theTimeInterval.getSampleFor(times(idx));
            
            for it=1:numel(samples)
                if isnan(samples(it))
                    time=times(it);
                    [~,I]=min(abs(time-ends));
                    times(it)=ends(I);
                end
            end
            samples=obj.getSampleFor(times);
        end
        
        function tiz=setZeitgeberTime(obj,zt)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            tiz=neuro.time.TimeIntervalZT(obj,zt);
        end
        function time=getEndTime(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            time=obj.StartTime+seconds((obj.NumberOfPoints-1)/obj.SampleRate);
            time.Format=obj.Format;
        end
        function time=getEndTimeZT(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            time1=obj.StartTime+seconds((obj.NumberOfPoints-1)/obj.SampleRate);
            time=time1-obj.getZeitgeberTime;
        end
        function timeIntervalList=getTimeIntervalList(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            timeIntervalList=CellArrayList();
            timeIntervalList.add(obj);
        end
        function timeIntervalCombined=plus(obj,timeInterval)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            timeIntervalCombined=neuro.time.TimeIntervalCombined(obj,timeInterval);
        end
        function [obj,residual]=getDownsampled(obj,downsampleFactor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.NumberOfPoints=floor(obj.NumberOfPoints/downsampleFactor);
            residual=mod(obj.NumberOfPoints,downsampleFactor);
            obj.SampleRate=round(obj.SampleRate/downsampleFactor);
        end
        function plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ts=obj.getTimeSeriesDownsampled(obj.SampleRate);
            p1=ts.plot;
            p1.LineWidth=5;
        end
        function st=getStartTime(obj)
            st=obj.StartTime;
            st.Format=obj.Format;
        end
        function tps=getTimePoints(obj,referencetime)
            try
                tps=linspace(0,obj.getEndTime-obj.getStartTime,obj.NumberOfPoints);
            catch ME
                
            end
            if exist('referencetime','var')
                diff1=seconds(obj.getStartTime-obj.getDatetime(referencetime));
                tps=tps+diff1;
            end
        end
        function tps=getTimePointsInAbsoluteTimes(obj)
            tps=obj.getTimePoints+obj.getStartTime;
        end
        function nop=getNumberOfPoints(obj)
            nop=obj.NumberOfPoints;
        end
        function sr=getSampleRate(obj)
            sr=obj.SampleRate;
        end
        function arrnew=adjustTimestampsAsIfNotInterrupted(obj,arr)
            arrnew=arr;
        end
        function ticd=saveTable(obj,filePath)
            S.StartTime=obj.StartTime;
            S.StartTime.Format='uuuu-MM-dd HH:mm:ss.SSS';
            S.NumberOfPoints=obj.NumberOfPoints;
            S.SampleRate=obj.SampleRate;
            try
                S.ZeitgeberTime=datestr(obj.ZeitgeberTime,'HH:MM');
            catch
            end
            T=struct2table(S);
            writetable(T,filePath)
            ticd=neuro.time.TimeIntervalCombined(filePath);
        end
        function obj=shiftTimePoints(obj,shift)
            obj.StartTime=obj.StartTime+shift.Duration;
        end

    end
end

