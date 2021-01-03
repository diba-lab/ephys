classdef TimeIntervalCombined
    %TIMEINTERVALCOMBINED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        timeIntervalList
        Format
    end
    
    methods
        function obj = TimeIntervalCombined(varargin)
            %TIMEINTERVALCOMBINED Construct an instance of this class
            %   Detailed explanation goes here
            timeIntervalList=CellArrayList();
            
            if nargin>0
                el=varargin{1};
                if isstring(el)||ischar(el)
                    T=readtable(el);
                    obj=TimeIntervalCombined;
                    for iti=1:height(T)
                        tiRow=T(iti,:);
                        theTimeInterval=TimeInterval(tiRow.StartTime,tiRow.SampleRate,tiRow.NumberOfPoints);
                        timeIntervalList.add(theTimeInterval);
                        fprintf('Record addded:');display(theTimeInterval);
                    end
                else
                    for iArgIn=1:nargin
                        theTimeInterval=varargin{iArgIn};
                        assert(isa(theTimeInterval,'TimeInterval'));
                        timeIntervalList.add(theTimeInterval);
                        fprintf('Record addded:');display(theTimeInterval);
                    end
                end
            end
            obj.timeIntervalList=timeIntervalList;
            obj.Format='dd-MMM-uuuu HH:mm:ss.SSS';
        end
        
        function new_timeIntervalCombined=getTimeIntervalForSamples(obj, startSample, endSample)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if startSample <1
                startSample=1;
                warning('Start sample is <1, \n\tit is set to ''1''\n')
            end
            if endSample > obj.getNumberOfPoints
                endSample=obj.getNumberOfPoints;
                warning('End sample is > number of point is TimeInterval %d, \n\tit is set that.\n', obj.getNumberOfPoints)
            end
            if startSample>0 && startSample<=endSample && endSample<=obj.getNumberOfPoints
                til=obj.timeIntervalList;
                lastSample=0;
                for iInt=1:til.length
                    theTimeInterval=til.get(iInt);
                    upstart=startSample-lastSample;
                    upend=endSample-lastSample;
                    if upend>0
                        newti=theTimeInterval.getTimeIntervalForSamples(upstart,upend);
                        if ~isempty(newti)
                            try
                                new_timeIntervalCombined=new_timeIntervalCombined+newti;
                            catch
                                new_timeIntervalCombined=newti;
                            end
                        end
                    end
                    lastSample=lastSample+theTimeInterval.NumberOfPoints;
                end
            else
                warning('Something wrong with the numbers. Please check if correct. \n\tThe same interval is returned.')
                new_timeIntervalCombined=obj;
            end
        end
        
        
        function timeIntervalCombined=getTimeIntervalForTimes(obj, startTime, endTime)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isduration(startTime)
                startTime=obj.convertDurationToDatetime(startTime);
            elseif isstring(startTime)
                t1=datetime(startTime,'Format','HH:mm');
                [h,m,s]=hms(obj.getStartTime);
                basetime=obj.getStartTime-hours(h)-minutes(m)-seconds(s);
                startTime=basetime+hours(t1.Hour)+minutes(t1.Minute);
            end
            if isduration(endTime)
                endTime=obj.convertDurationToDatetime(endTime);
            elseif isstring(endTime)
                t1=datetime(endTime,'Format','HH:mm');
                [h,m,s]=hms(obj.getStartTime);
                basetime=obj.getStartTime-hours(h)-minutes(m)-seconds(s);
                endTime=basetime+hours(t1.Hour)+minutes(t1.Minute);
            end
            if startTime<obj.getStartTime
                startTime=obj.getStartTime+seconds(1);
            end
            if endTime>obj.getEndTime
                endTime=obj.getEndTime-seconds(1);
            end
            times=obj.getSampleFor([startTime endTime]);
            timeIntervalCombined=obj.getTimeIntervalForSamples(times(1),times(2));
        end
        
        function times=getRealTimeFor(obj,samples)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for isample=1:numel(samples)
                sample=samples(isample);
                newSample=0;
                if sample>0 && sample<obj.getNumberOfPoints
                    til= obj.timeIntervalList;
                    for iInt=1:til.length
                        theTimeInterval=til.get(iInt);
                        lastSample=newSample;
                        newSample=lastSample+theTimeInterval.NumberOfPoints;
                        if sample>lastSample && sample<=newSample
                            time=theTimeInterval.getRealTimeFor(double(sample)-lastSample);
                        end
                    end
                else
                    time=datetime('today');
                    time.Format=obj.Format;
                    warning('Sample is not in the TimeInterval -- should be between\n\t%d -- %d\nReturned ''%s''',1,obj.NumberOfPoints,datestr(time));
                end
                time.Format=obj.Format;
                times(isample)=time;
            end
        end
        
        function samples=getSampleFor(obj,times)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for itime=1:numel(times)
                time=times(itime);
                
                lastSample=0;
                if ~isdatetime(times)
                    if isduration(time)
                        time=obj.convertDurationToDatetime(time);
                    elseif isstring(time{1})||ischar(time{1})
                        time=obj.convertStringToDatetime(time);
                    end
                end
                %                 time.Second=floor(time.Second);
                if time<obj.getStartTime
                    %                     warning('Given time(%s) is earlier then record start(%s).\n',...
                    %                         time,obj.getStartTime);
                    time=obj.getStartTime;
                elseif time>obj.getEndTime
                    %                     warning('Given time(%s) is later then record end(%s).\n',...
                    %                         time,obj.getEndTime);
                    time=obj.getEndTime;
                end
                
                
                til= obj.timeIntervalList;
                found=0;
                for iInt=1:til.length
                    if ~found
                        theTimeInterval=til.get(iInt);
                        if time>=theTimeInterval.StartTime
                            if time<=theTimeInterval.getEndTime
                                sample=theTimeInterval.getSampleFor(time)+lastSample;
                                found=1;
                            end
                        else
                            sample=1+lastSample;
                            found=1;
                        end
                        
                        lastSample=lastSample+theTimeInterval.NumberOfPoints;
                    end
                end
                samples(itime)=sample;
            end
        end
        
        function time=getEndTime(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            til= obj.timeIntervalList;
            theTimeInterval=til.get(til.length);
            time=theTimeInterval.getEndTime;
            time.Format=obj.Format;
        end
        
        function obj = plus(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for iArgIn=1:nargin-1
                theTimeInterval=varargin{iArgIn};
                if ~isempty(theTimeInterval)
                    try
                        assert(isa(theTimeInterval,'TimeInterval'));
                        obj.timeIntervalList.add(theTimeInterval);
                        fprintf('Record addded:');display(theTimeInterval);
                    catch
                        assert(isa(theTimeInterval,'TimeIntervalCombined'));
                        til=theTimeInterval.timeIntervalList.createIterator;
                        while(til.hasNext)
                            obj.timeIntervalList.add(til.next);
                        end
                    end
                end
            end
        end
        
        function numberOfPoints=getNumberOfPoints(obj)
            til= obj.timeIntervalList;
            numberOfPoints=0;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                numberOfPoints=numberOfPoints+theTimeInterval.NumberOfPoints;
            end
        end
        function sampleRate=getSampleRate(obj)
            til= obj.timeIntervalList;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                if ~exist('sampleRate', 'var')
                    sampleRate=theTimeInterval.SampleRate;
                else
                    assert(sampleRate==theTimeInterval.SampleRate);
                end
            end
        end
        function startTime=getStartTime(obj)
            til= obj.timeIntervalList;
            theTimeInterval=til.get(1);
            startTime=theTimeInterval.getStartTime;
        end
        function [timeIntervalCombined,resArr]=getDownsampled(obj,downsampleFactor)
            til= obj.timeIntervalList;
            resArr=[];
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                [ds_ti, residual]=theTimeInterval.getDownsampled(downsampleFactor);
                if iInt==1
                    residuals(iInt,1)=ds_ti.NumberOfPoints*downsampleFactor+1;
                    residuals(iInt,2)=ds_ti.NumberOfPoints*downsampleFactor+residual;
                else
                    numPointsPrev=residuals(iInt-1,2);
                    residuals(iInt,1)=numPointsPrev+ds_ti.NumberOfPoints*downsampleFactor+1;
                    residuals(iInt,2)=numPointsPrev+ds_ti.NumberOfPoints*downsampleFactor+residual;
                end
                resArr=[resArr residuals(iInt,1):residuals(iInt,2)];
                if exist('timeIntervalCombined','var')
                    timeIntervalCombined=timeIntervalCombined+ds_ti;
                else
                    timeIntervalCombined=ds_ti;
                end
                
            end
            
        end
        function tps=getTimePointsInSec(obj)
            til= obj.timeIntervalList;
            st=obj.getStartTime;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                tp=theTimeInterval.getTimePointsInSec+seconds(theTimeInterval.getStartTime-st);
                if exist('tps','var')
                    tps=horzcat(tps, tp);
                else
                    tps=tp;
                end
            end
        end
        function tps=getTimePointsInAbsoluteTimes(obj)
            tps=seconds(obj.getTimePointsInSec)+obj.getStartTime;
        end
        function tps=getTimePointsInSamples(obj)
            
            %             secs=obj.getTimePointsInSec
            %             tps(end)=[];
        end
        function arrnew=adjustTimestampsAsIfNotInterrupted(obj,arr)
            arrnew=arr;
            til= obj.timeIntervalList;
            st=obj.getStartTime;
            for iAdj=1:til.length
                theTimeInterval=til.get(iAdj);
                tistart=theTimeInterval.getStartTime;
                
                if iAdj==1
                    sample(iAdj).adj=0;
                    sample(iAdj).begin=1;
                    sample(iAdj).end=theTimeInterval.NumberOfPoints;
                else
                    tiprev=til.get(iAdj-1);
                    adjustinthis=seconds(theTimeInterval.getStartTime-tiprev.getEndTime)*...
                        obj.getSampleRate;
                    sample(iAdj).adj=sample(iAdj-1).adj+adjustinthis;
                    sample(iAdj).begin=sample(iAdj-1).end+1;
                    sample(iAdj).end=sample(iAdj).begin+theTimeInterval.NumberOfPoints;
                end
                idx=(arr>=sample(iAdj).begin)&(arr<=sample(iAdj).end);
                arrnew(idx)=arr(idx) + sample(iAdj).adj;
            end
            %             tps(end)=[];
        end
        function ti=mergeTimeIntervals(obj)
            til= obj.timeIntervalList;
            st=obj.getStartTime;
            
            ti=TimeInterval(obj.getStartTime, obj.getSampleRate, obj.getNumberOfPoints);
            %             tps(end)=[];
        end
        
        function plot(obj)
            til=obj.timeIntervalList;
            iter=til.createIterator;
            while iter.hasNext
                theTimeInterval=iter.next;
                theTimeInterval.plot;hold on;
            end
        end
        function save(obj,folder)
            filename=fullfile(folder,'_added_TimeIntervalCombined.mat');
            save(filename,'obj');
        end
        function ticd=saveTable(obj,filePath)
            iter=obj.timeIntervalList.createIterator;
            count=1;
            
            while(iter.hasNext)
                ti=iter.next;
                S(count).StartTime=ti.StartTime;
                S(count).NumberOfPoints=ti.NumberOfPoints;
                S(count).SampleRate=ti.SampleRate;
                count=count+1;
            end
            T=struct2table(S);
            writetable(T,filePath)
            ticd=TimeIntervalCombined(filePath);
        end
        function ticd=readTimeIntervalTable(obj,table)
            T=readtable(table);
            ticd=TimeIntervalCombined;
            for iti=1:height(T)
                tiRow=T(iti,:);
                ti=TimeInterval(tiRow.StartTime,tiRow.SampleRate,tiRow.NumberOfPoints);
                ticd=ticd+ti;
            end
        end
        
    end
    methods
        function dt=convertDurationToDatetime(obj,time)
            st=obj.getStartTime;
            dt=datetime(st.Year,st.Month,st.Day)+time;
        end
        function dt=convertStringToDatetime(obj,time)
            st=obj.getStartTime;
            dt1=datetime(time,'Format','HH:mm');
            dt=datetime(st.Year,st.Month,st.Day)+hours(dt1.Hour)+minutes(dt1.Minute);
        end
    end
end
