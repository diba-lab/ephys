classdef TimeInterval < neuro.time.TimeIntervalAbstract
    %TimeInterval Represents a time interval and provides methods for working with it

    properties
        StartTime   % Start time of the interval
        SampleRate  % Sampling rate of the interval
        NumberOfPoints % Number of data points in the interval
    end
    methods
        function obj = TimeInterval(startTime, sampleRate, numberOfPoints)
            % Constructor method that initializes the TimeInterval object
            % with the specified start time, sampling rate, and number of data points.
            obj.SampleRate = sampleRate;
            obj.StartTime=startTime;
            obj.StartTime.Format='uuuu-MM-dd HH:mm:ss.SSS';
            obj.NumberOfPoints=numberOfPoints;
            obj.Format = 'HH:mm:ss.SSS'; % Format of the timestamps in the interval

        end
        function []=print(obj)
            % Print method that prints a string representation of the 
            % TimeInterval object to the console.
            fprintf('%s',obj.tostring);
        end
        function str=tostring(obj)
            % Tostring method that returns a string representation of the TimeInterval object.
            date = obj.getDate;
            date.Format='yyyy-MM-dd';
            st = char(obj.getStartTime, 'HH:mm:ss.SSS');
            en = char(obj.getEndTime, 'HH:mm:ss.SSS');
            dur = obj.getEndTime - obj.getStartTime;
            dur1 = char(dur,"hh:mm:ss.SSS");        
            sf=obj.getSampleRate;
            np=obj.getNumberOfPoints;
            jf=java.text.DecimalFormat; % comma for thousands, three decimal places
            np1= char(jf.format(np)); % omit "char" if you want a string out

            str=sprintf('\t%s \t%s - %s\t<%s>\t<%s (%dHz)> \n',date,st,en,dur1,np1,sf);
        end
        function S=getStruct(obj)
            % GetStruct method that returns a structure with the
            % SampleRate, StartTime, and NumberOfPoints properties of the TimeInterval object.
            S.StartTime=obj.StartTime;
            S.NumberOfPoints=obj.NumberOfPoints;
            S.SampleRate=obj.SampleRate;
        end
        function newTimeInterval = getTimeIntervalForSamples(obj, varargin)
            % GetTimeIntervalForSamples method that returns a new TimeInterval object
            % that corresponds to a subset of the data in the original interval,
            % specified by a range of sample indices or a range of data points.

            if nargin > 2
                startSample = varargin{1};
                endSample = varargin{2};
            else
                range = varargin{1};
                startSample = range(1);
                endSample = range(2);
            end

            if startSample > obj.NumberOfPoints || endSample < 1
                newTimeInterval = [];
                return
            elseif startSample > 0 && startSample <= obj.NumberOfPoints
                obj.StartTime = obj.getRealTimeFor(startSample);
                if endSample <= obj.NumberOfPoints
                    obj.NumberOfPoints = endSample - startSample + 1;
                else
                    obj.NumberOfPoints = obj.NumberOfPoints - startSample + 1;
                end
            else % start sample is smaller than 0, no change in start time
                if endSample < obj.NumberOfPoints
                    obj.NumberOfPoints = endSample;
                else
                    % no change in NumberOfPoints
                end
                % no change in start time
            end

            newTimeInterval = obj;
        end
        function timeIntervals=getTimeIntervalForTimes(obj,windows)
            % GetTimeIntervalForTimes method that returns an array of TimeInterval objects
            % that correspond to a set of time intervals specified by a set of datetime
            % objects or a set of durations.
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
            % GetRealTimeFor method that returns an array of datetime objects
            % that correspond to a set of sample indices in the interval.
            idx=samples>0 & samples<=obj.NumberOfPoints;
            if numel(idx)>0
                validsamples = zeros(sum(idx), size(samples, 2));
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
            % GetSampleFor method that returns an array of sample indices
            % that correspond to a set of datetime objects in the interval.
            samples=nan(size(times));
            startTime=obj.StartTime;
            endTime=obj.getEndTime;
            for i=1:numel(times)
                time=times(i);
                if time>=startTime && time<=endTime
                    samples(i)=round(seconds(time-obj.StartTime)*obj.SampleRate)+1;
                    if samples(i)<1
                        samples(i)=1;
                    end
                end
            end
        end
        function samples = getSampleForClosest(obj, datetimes)
            % GetSampleForClosest method that returns an array of sample indices
            % that correspond to a set of datetime objects in the interval,
            % where each datetime object is matched to the closest sample index in the interval.
            datetimes = obj.getDatetime(datetimes);

            samples = nan(size(datetimes));

            theInterval = obj;
            ends(1) = theInterval.getStartTime;
            ends(2) = theInterval.getEndTime;
            idx = datetimes >= theInterval.StartTime & ...
                datetimes <= theInterval.getEndTime;
            samples(idx) = theInterval.getSampleFor(datetimes(idx));

            for it = 1:numel(samples)
                if isnan(samples(it))
                    datetime = datetimes(it);
                    [~, I] = min(abs(datetime - ends));
                    datetimes(it) = ends(I);
                end
            end
            samples = obj.getSampleFor(datetimes);
        end
        % A constructor method that initializes the TimeIntervalZT
        % object with the specified Zeitgeber Time.
        function tiz=setZeitgeberTime(obj,zt)
            % Set the Zeitgeber Time of the TimeIntervalZT object
            tiz=neuro.time.TimeIntervalZT(obj,zt);
        end
        % A method that returns the end time of the TimeInterval object
        function time=getEndTime(obj)
            % Compute the end time of the TimeInterval object
            time=obj.StartTime+seconds((obj.NumberOfPoints-1)/obj.SampleRate);
            % Set the format of the time object to the same as the start time object
            time.Format=obj.Format;
        end
        % A method that returns the end time of the TimeIntervalZT object
        function time=getEndTimeZT(obj)
            % Compute the end time of the TimeIntervalZT object
            time1=obj.StartTime+seconds((obj.NumberOfPoints-1)/obj.SampleRate);
            % Subtract the Zeitgeber Time from the computed end time to get
            % the end time in the Zeitgeber Time zone
            time=time1-obj.getZeitgeberTime;
        end
        % A method that returns a CellArrayList containing the TimeInterval object
        function timeIntervalList=getTimeIntervalList(obj)
            % Create a CellArrayList object containing the TimeInterval object
            timeIntervalList=CellArrayList();
            timeIntervalList.add(obj);
        end
        % A method that combines two TimeInterval objects into a TimeIntervalCombined object
        function timeIntervalCombined=plus(obj,timeInterval)
            % Create a TimeIntervalCombined object containing the two TimeInterval objects
            timeIntervalCombined=neuro.time.TimeIntervalCombined(obj,timeInterval);
        end
        % A method that returns a downsampled TimeInterval object
        function [obj,residual]=getDownsampled(obj,downsampleFactor)
            % Compute the new number of data points and the residual number of data points
            obj.NumberOfPoints=floor(obj.NumberOfPoints/downsampleFactor);
            residual=mod(obj.NumberOfPoints,downsampleFactor);
            % Compute the new sampling rate
            obj.SampleRate=round(obj.SampleRate/downsampleFactor);
        end
        % A method that plots the TimeInterval object
        function plot(obj)
            % Get a downsampled time series object with the same sampling
            % rate as the TimeInterval object
            ts=obj.getTimeSeriesDownsampled(obj.SampleRate);
            p1=ts.plot;
            p1.LineWidth=5;
        end
        % A method that returns the start time of the TimeInterval object
        function st=getStartTime(obj)
            % Get the start time of the TimeInterval object
            st=obj.StartTime;
            % Set the format of the time object to the same as the start time object
            st.Format=obj.Format;
        end
        % A method that returns an array of time points for the TimeInterval object
        %
        % Input:
        %   obj: a TimeInterval object
        %   referenceTime (optional): a datetime object specifying the reference time to
        %                             shift the time points (default is no shift)
        %
        % Output:
        %   timePoints: an array of time points representing the equally spaced
        %               sequence of numbers from 0 to the duration of the interval
        %               (in seconds)
        function timePoints = getTimePoints(obj, referenceTime)
            try
                % Compute the time points as the sequence of equally spaced
                % numbers from 0 to the duration of the interval
                duration = obj.getEndTime - obj.getStartTime;
                numPoints = obj.NumberOfPoints;
                timePoints = linspace(0, duration, numPoints);
            catch ME
                % Handle any errors that occur during the computation of time points
                error('Error computing time points: %s', ME.message);
            end

            % If a reference time is specified, shift the time points by
            % the difference between the start time and the reference time
            if exist('referenceTime', 'var')
                startTime = obj.getStartTime;
                refTime = obj.getDatetime(referenceTime);
                timeDifference = seconds(startTime - refTime);
                timePoints = timePoints + timeDifference;
            end
        end
        % A method that returns an array of time points for the TimeInterval
        % object in absolute times
        function tps=getTimePointsInAbsoluteTimes(obj)
            tps=obj.getTimePoints+obj.getStartTime;
        end
        function nop=getNumberOfPoints(obj)
            nop=obj.NumberOfPoints;
        end
        function sr=getSampleRate(obj)
            sr=obj.SampleRate;
        end
        function arrnew=adjustTimestampsAsIfNotInterrupted(~,arr)
            arrnew=arr;
        end
        function ticd=saveTable(obj,filePath)
            % Convert relevant properties of the TimeInterval object to a struct
            S.StartTime = datetime(obj.StartTime,'Format', ...
                'yyyy-MM-dd HH:mm:ss.SSS'); % convert to string format
            S.NumberOfPoints=obj.NumberOfPoints;
            S.SampleRate=obj.SampleRate;
            if ~isempty(obj.ZeitgeberTime)
                S.ZeitgeberTime = datetime(obj.ZeitgeberTime,'Format', ...
                    'HH:mm'); % convert to string format
            end

            % Convert the struct to a table and write to file
            T=struct2table(S);
            writetable(T,filePath)

            % Create a new TimeIntervalCombined object from the saved file
            ticd=neuro.time.TimeIntervalCombined(filePath);
        end        function obj=shiftTimePoints(obj,shift)
            obj.StartTime=obj.StartTime+shift.Duration;
        end

    end
end

