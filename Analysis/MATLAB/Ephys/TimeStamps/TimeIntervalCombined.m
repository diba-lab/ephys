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
            for iArgIn=1:nargin
                theTimeInterval=varargin{iArgIn};
                assert(isa(theTimeInterval,'TimeInterval'));
                timeIntervalList.add(theTimeInterval);
                fprintf('Record addded:');display(theTimeInterval);
            end
            obj.timeIntervalList=timeIntervalList;
            obj.Format='dd-MMM-uuuu HH:mm:ss.SSS';
        end
        
        function timeIntervalCombined=getTimeIntervalForSamples(obj, startSample, endSample)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            timeIntervalCombined=TimeIntervalCombined;
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
                    timeIntervalCombined=timeIntervalCombined+theTimeInterval.getTimeIntervalForSamples(startSample-lastSample,endSample-lastSample);
                    lastSample=lastSample+theTimeInterval.NumberOfPoints;
                end
            else
                warning('Something wrong with the numbers. Please check if correct. \n\tThe same interval is returned.')
                timeIntervalCombined=obj;
            end
        end
        
        function timeIntervalCombined=getTimeIntervalForTimes(obj, startTime, endTime)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if startTime<obj.getStartTime
                startTime=obj.getStartTime+seconds(1);
            end
            if endTime>obj.getEndTime
                endTime=obj.getEndTime-seconds(1);
            end
            startSample=obj.getSampleFor(startTime);
            endSample=obj.getSampleFor(endTime);
            timeIntervalCombined=obj.getTimeIntervalForSamples(startSample,endSample);
        end
        
        function time=getRealTimeFor(obj,sample)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            newSample=0;
            if sample>0 && sample<obj.getNumberOfPoints
                til= obj.timeIntervalList;
                for iInt=1:til.length
                    theTimeInterval=til.get(iInt);
                    lastSample=newSample;
                    newSample=lastSample+theTimeInterval.NumberOfPoints;
                    if sample>lastSample && sample<=newSample
                        time=theTimeInterval.getRealTimeFor(sample-lastSample);
                    end
                end
            else
                time=datetime('today');
                time.Format=obj.Format;
                warning('Sample is not in the TimeInterval -- should be between\n\t%d -- %d\nReturned ''%s''',1,obj.NumberOfPoints,datestr(time));
            end
            time.Format=obj.Format;
        end
        
        function sample=getSampleFor(obj,time)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            lastSample=0;
            time.Second=floor(time.Second);
            if time>=obj.getStartTime && time<=obj.getEndTime
                til= obj.timeIntervalList;
                for iInt=1:til.length
                    theTimeInterval=til.get(iInt);
                    if time>=theTimeInterval.StartTime && time<=theTimeInterval.getEndTime
                        sample=theTimeInterval.getSampleFor(time)+lastSample;
                    end
                    lastSample=lastSample+theTimeInterval.NumberOfPoints;
                end
            else
                time=datetime('today');
                time.Format=obj.Format;
                warning('Sample is not in the TimeInterval -- should be between\n\t%d -- %d\nReturned ''%s''',1,obj.getNumberOfPoints,datestr(time));
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
                    assert(isa(theTimeInterval,'TimeInterval'));
                    obj.timeIntervalList.add(theTimeInterval);
                    fprintf('Record addded:');display(theTimeInterval);
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
        function timeIntervalCombined=getDownsampled(obj,downsampleFactor)
            til= obj.timeIntervalList;
            for iInt=1:til.length
                theTimeInterval=til.get(iInt);
                if exist('timeIntervalCombined','var')
                    timeIntervalCombined=timeIntervalCombined+theTimeInterval.getDownsampled(downsampleFactor);
                else
                    timeIntervalCombined=theTimeInterval.getDownsampled(downsampleFactor);
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
                    tps=vertcat(tps, tp);
                else
                    tps=tp;
                end
            end
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
    end
end
