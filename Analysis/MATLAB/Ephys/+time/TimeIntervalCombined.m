classdef TimeIntervalCombined < time.TimeIntervalAbstract
    %TIMEINTERVALCOMBINED Summary of this class goes here
    %   Detailed explanation goes here

    
    properties
        timeIntervalList
        Source
    end
    
    methods
        function obj = TimeIntervalCombined(varargin)
            import time.*
            logger=logging.Logger.getLogger;
            %TIMEINTERVALCOMBINED Construct an instance of this class
            %   Detailed explanation goes here
            timeIntervalList=CellArrayList();
            if nargin>0
                el=varargin{1};
                if isstring(el)||ischar(el)
                    if isfolder(el)
                        timefile=dir(fullfile(el,sprintf('*TimeInterval*')));
                        if numel(timefile)==1
                            timefilefinal=timefile;
                        elseif numel(timefile)>1
                            [~,ind]=sort(datetime({timefile.date}));
                            timefiles = timefile(flip(ind));
                            timefilefinal=timefiles(1);
                            logger.warning(['\nMultiple Time files. Selecting' ...
                                ' the latest.\n  -->\t%s\n\t%s'],timefiles.name)
                        else
                            logger.error('\nNo Time file found in\n\t\%s',el);
                        end
                        timefilepath=fullfile(timefilefinal.folder,timefilefinal.name);
                    else
                        timefilepath=el;
                    end
                    % try to find zeitgebver time
                    try
                        sf=experiment.SessionFactory;
                        folder=fileparts(timefilepath);
                        ses=sf.getSessions(folder);
                        zt=ses.SessionInfo.ZeitgeberTime;
                    catch
                    end
                    try
                        T=readtable(timefilepath);
                        obj=TimeIntervalCombined;
                        for iti=1:height(T)
                            tiRow=T(iti,:);
                            theTimeInterval=TimeInterval(tiRow.StartTime, ...
                                tiRow.SampleRate,tiRow.NumberOfPoints);
                            if ismember('ZeitgeberTime',tiRow.Properties.VariableNames)
                                zt=tiRow.ZeitgeberTime;
                                if iscell(zt)
                                    zt=duration(zt{1},"InputFormat","hh:mm");
                                end
                            end
                            if exist('zt','var')
                                theTimeInterval=time.TimeIntervalZT( ...
                                    theTimeInterval,zt);
                            end
                            timeIntervalList.add(theTimeInterval);
                            logger.fine('ti added.');
                        end
                        obj.Source=timefilepath;
                    catch
                        S=load(timefilepath);
                        logger.fine('til loaded.');
                        timeIntervalList=S.obj.timeIntervalList;
                    end
                    
                else
                    for iArgIn=1:nargin
                        theTimeInterval=varargin{iArgIn};
                        if isa(theTimeInterval,'TimeInterval')
                            timeIntervalList.add(theTimeInterval);
                            logger.fine('ti added.');
                        elseif isa(theTimeInterval,'TimeIntervalCombined')
                            iter=theTimeInterval.timeIntervalList.createIterator;
                            while iter.hasNext
                                timeIntervalList.add(iter.next)
                            end
                        end
                    end
                end
                try
                    obj.timeIntervalList=timeIntervalList;
                    obj=obj.setZeitgeberTime(timeIntervalList.get(1).ZeitgeberTime);
                catch
                end
            end
            try obj.Source=timefilepath;catch,end
            if isempty(obj.timeIntervalList)
                obj.timeIntervalList=CellArrayList();
            end
            try obj=obj.sort; catch, end
            obj.Format='uuuu-MM-dd HH:mm:ss.SSS';
        end
        
        function []=print(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            til=obj.timeIntervalList;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                theTimeInterval.print
            end
        end
        function [obj]=sort(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            til=obj.timeIntervalList;
            for iInt=1:til.length
                theTimeInterval(iInt)=til.get(iInt);  
                st(iInt)=theTimeInterval(iInt).getStartTime;  
            end
            [~,I]=sort(st);
            til.remove(1:numel(I));
            for iInt=1:numel(I)
                til.add(theTimeInterval(I(iInt)));
            end
        end
        function str=tostring(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            date=datestr(obj.getDate,1);
            st=datestr( obj.getStartTime,13);
            en=datestr(obj.getEndTime,13);
            dur=obj.getEndTime-obj.getStartTime;
            dur1=datestr(dur,13);
            sf=obj.getSampleRate;
            np=obj.getNumberOfPoints;
            jf=java.text.DecimalFormat; % comma for thousands, three decimal places
            np1= char(jf.format(np)); % omit "char" if you want a string out
            str=sprintf('\t%s \t%s - %s\t<%s>\t<%s (%dHz)>',date,st,en,dur1,np1,sf);
        end
        function tostringList(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.print;
        end
        function new_timeIntervalCombined=getTimeIntervalForSamples(obj, samples)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for i=1:size(samples,1)
                sampleint=samples(i,:);
                if sampleint(1) <1
                    sampleint(1)=1;
                end
                if sampleint(2) > obj.getNumberOfPoints
                    sampleint(2)=obj.getNumberOfPoints;
                end
                if any(samples(:,1)>samples(:,2))
                    new_timeIntervalCombined=[];
                else
                    til=obj.timeIntervalList;
                    lastSample=0;
                    for iInt=1:til.length
                        theTimeInterval=til.get(iInt);
                        upstart=sampleint(1)-lastSample;
                        upend=sampleint(2)-lastSample;
                        if upend>0 % not already assigned
                            newti=theTimeInterval.getTimeIntervalForSamples(...
                                upstart,upend);
                            if ~isempty(newti)
                                try
                                    new_timeIntervalCombined=...
                                        new_timeIntervalCombined+newti;
                                catch
                                    new_timeIntervalCombined=newti;
                                end
                            end
                        end
                        lastSample=lastSample+theTimeInterval.NumberOfPoints;
                    end
                end
            end
        end

        function timeIntervalList=getTimeIntervalList(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            timeIntervalList=obj.timeIntervalList;
        end

        function timeIntervalCombined=getTimeIntervalForTimes(obj, times)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=obj.getDatetime(times);
            timess=obj.getSampleForClosest(times);
            timeIntervalCombined=obj.getTimeIntervalForSamples(timess);
        end
        
        function times=getRealTimeFor(obj,samples)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if numel(samples)>1e5
                tps=obj.getTimePointsInAbsoluteTimes;
                times=tps(samples);
            else
                for isample=1:numel(samples)
                    sample=samples(isample);
                    newSample=0;
                    til= obj.timeIntervalList;
                    for iInt=1:til.length
                        theTimeInterval=til.get(iInt);
                        lastSample=newSample;
                        newSample=lastSample+theTimeInterval.NumberOfPoints;
                        if sample>lastSample && sample<=newSample
                            time=theTimeInterval.getRealTimeFor(double( ...
                                sample)-lastSample);
                        end
                    end
                    time.Format=obj.Format;
                    times(isample)=time;  
                end
            end
        end
        
        function samples=getSampleFor(obj,times)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=obj.getDatetime(times);
            samples=nan(size(times));
            til= obj.timeIntervalList;
                lastSample=0;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                idx=times>=theTimeInterval.StartTime&times<=theTimeInterval.getEndTime;
                samples(idx)=theTimeInterval.getSampleFor(times(idx))+lastSample;
                lastSample=lastSample+theTimeInterval.NumberOfPoints;         
            end
        end
        function samples=getSampleForClosest(obj,times)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=obj.getDatetime(times);

            samples=nan(size(times));
            til= obj.timeIntervalList;
            lastSample=0;
            ends=datetime.empty([til.length 0]);
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                ends((iInt-1)*2+1,1)=theTimeInterval.getStartTime;
                ends(iInt*2,1)=theTimeInterval.getEndTime;
                idx=times>theTimeInterval.getStartTime & ...
                    times<=theTimeInterval.getEndTime;
                samples(idx)=theTimeInterval.getSampleFor(...
                    times(idx))+lastSample;
                lastSample=lastSample+theTimeInterval.NumberOfPoints;
            end
            for it=1:numel(samples)
                if isnan(samples(it))
                    time=times(it);
                    [~,I]=min(abs(time-ends));
                    times(it)=ends(I);
                end
            end
            samples=obj.getSampleFor(times);
        end
        
        function time=getEndTime(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            til= obj.timeIntervalList;
            theTimeInterval=til.get(til.length);
            time=theTimeInterval.getEndTime;
            time.Format=obj.Format;
        end
        function time=getEndTimeZT(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            time=obj.getEndTime-obj.getZeitgeberTime;
        end
        
        function ticdnew = plus(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ticdnew=time.TimeIntervalCombined;
            for it=1:obj.timeIntervalList.length
                ticdnew.timeIntervalList.add(obj.timeIntervalList.get(it));
            end
            for iArgIn=1:nargin-1
                theTimeInterval=varargin{iArgIn};
                if ~isempty(theTimeInterval)
                    try
                        for it=1:theTimeInterval.timeIntervalList.length
                            ticdnew.timeIntervalList.add( ...
                                theTimeInterval.timeIntervalList.get(it));
                        end
                        l=logging.Logger.getLogger;
                        l.fine(sprintf('\nRecord addded:\n%s', ...
                            theTimeInterval.tostring));
                    catch
                         ticdnew.timeIntervalList.add(theTimeInterval);
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
        function startTime=getStartTimeZT(obj)
            til= obj.timeIntervalList;
            theTimeInterval=til.get(1);
            startTime=theTimeInterval.getStartTimeZT;
        end
        function [timeIntervalCombined, residualthis]=getDownsampled( ...
                obj,downsampleFactor)
            til= obj.timeIntervalList;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                if iInt>1
                    residualprev=residualthis;
                    residualtime=seconds(residualprev/theTimeInterval.SampleRate);
                    theTimeInterval.StartTime=theTimeInterval.StartTime-residualtime;
                    theTimeInterval.NumberOfPoints=...
                        theTimeInterval.NumberOfPoints+residualprev;
                end
                [ds_ti, residualthis]=theTimeInterval.getDownsampled(downsampleFactor);
                if exist('timeIntervalCombined','var')
                    timeIntervalCombined=timeIntervalCombined+ds_ti;
                else
                    timeIntervalCombined=ds_ti;
                end
                
            end
            try timeIntervalCombined.Source= obj.Source;catch, end
        end
        function tps=getTimePoints(obj)
            til= obj.timeIntervalList;
            st=obj.getStartTime;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                tp=theTimeInterval.getTimePoints+theTimeInterval.getStartTime-st;
                if exist('tps','var')
                    tps=horzcat(tps, tp); %#ok<*AGROW> 
                else
                    tps=tp;
                end
            end
        end
        function tps=getTimePointsZT(obj)
            til= obj.timeIntervalList;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                tp=theTimeInterval.getTimePointsZT;
                if exist('tps','var')
                    tps=horzcat(tps, tp); %#ok<*AGROW> 
                else
                    tps=tp;
                end
            end
        end
        function tps=getTimePointsInAbsoluteTimes(obj)
            tps=obj.getTimePoints+obj.getStartTime;
        end
        function tps=getTimePointsInSamples(obj)
            tps=1:obj.getNumberOfPoints;
        end
        function arrnew=adjustTimestampsAsIfNotInterrupted(obj,arr)
            arrnew=arr;
            til= obj.timeIntervalList;
            for iAdj=1:til.length
                theTimeInterval=til.get(iAdj);
                if iAdj==1
                    sample(iAdj).adj=0;
                    sample(iAdj).begin=1;
                    sample(iAdj).end=theTimeInterval.NumberOfPoints;
                else
                    tiprev=til.get(iAdj-1);
                    adjustinthis=seconds(theTimeInterval.getStartTime- ...
                        tiprev.getEndTime)*obj.getSampleRate;
                    sample(iAdj).adj=sample(iAdj-1).adj+adjustinthis;
                    sample(iAdj).begin=sample(iAdj-1).end+1;
                    sample(iAdj).end=sample(iAdj).begin+theTimeInterval.NumberOfPoints;
                end
                idx=(arr>=sample(iAdj).begin)&(arr<=sample(iAdj).end);
                arrnew(idx)=arr(idx) + sample(iAdj).adj;
            end
        end
        function ti=mergeTimeIntervals(obj)
            ti=time.TimeInterval(obj.getStartTime, obj.getSampleRate, ...
                obj.getNumberOfPoints);
        end
        
        function plot(obj)
            til=obj.timeIntervalList;
            iter=til.createIterator;
            while iter.hasNext
                theTimeInterval=iter.next;
                try
                    theTimeInterval.plot;hold on;
                catch ME
                    if ~strcmp(ME.message,['setuniformtime requires ' ...
                            'a timeseries with at least one sample.'])
                        error(ME);
                    end
                end
            end
        end
        function save(obj,folder)
            filename=fullfile(folder,'_added_TimeIntervalCombined.mat');
            save(filename,'obj');
        end
        function ticd=saveTable(obj,filePath)
            iter=obj.timeIntervalList.createIterator;
            count=1;
            if ~exist('filePath','var')
                filePath=obj.Source;
            end
            while(iter.hasNext)
                ti=iter.next;
                zt=ti.getStruct;
                zt.StartTime.Format='uuuu-MM-dd HH:mm:ss.SSS';
                if isfield(zt,'ZeitgeberTime')
                    zt.ZeitgeberTime=datestr(zt.ZeitgeberTime,'HH:MM');
                end
                S(count)=zt;count=count+1;
            end
            T=struct2table(S);
            writetable(T,filePath);
            ticd=time.TimeIntervalCombined(filePath);
        end
        function ticd=readTimeIntervalTable(~,table)
            T=readtable(table);
            ticd=time.TimeIntervalCombined;
            for iti=1:height(T)
                tiRow=T(iti,:);
                ti=time.TimeInterval(tiRow.StartTime, ...
                    tiRow.SampleRate,tiRow.NumberOfPoints);
                ticd=ticd+ti;
            end
        end
        function ticd=setZeitgeberTime(obj,zt)
            ticd=time.TimeIntervalCombined;
            iter=obj.timeIntervalList.createIterator;
            if isduration(zt)
                zt=zt+obj.getDate;
            end
            while(iter.hasNext)
                ti=iter.next;
                tiz=time.TimeIntervalZT(ti,zt);
                ticd=ticd+tiz;
            end
            ticd.Source=obj.Source;
        end
        function zt=getZeitgeberTime(obj)
            iter=obj.timeIntervalList.createIterator;
            ti=iter.next;
            if isa(ti,"time.TimeIntervalZT")
                zt=ti.getZeitgeberTime;
            else
                zt=[];
            end
        end
        function obj=shiftTimePoints(obj,shift)
            tilnew=CellArrayList;
            til= obj.timeIntervalList;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                ti=theTimeInterval.shiftTimePoints(shift);
                tilnew.add(ti);
            end
            obj.timeIntervalList=tilnew;
        end    
        function obj=addTimePoints(obj,num)
            tilnew=CellArrayList;
            til= obj.timeIntervalList;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                if iInt==til.length
                    theTimeInterval.NumberOfPoints=...
                        theTimeInterval.NumberOfPoints+num;
                end
                tilnew.add(theTimeInterval);
            end
            obj.timeIntervalList=tilnew;
        end
    end
    methods

        
    end
end
