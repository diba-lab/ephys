classdef VideoFile < VideoReader
    %VIDEOFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        StartTime
    end
    
    methods
        function obj = VideoFile(filename)
            %VIDEOFILE Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@VideoReader(filename);
            [~,name,~]=fileparts(obj.Name);
            timecsv=strcat(name,'.csv');
            ti=neuro.time.TimeInterval([],obj.FrameRate,obj.NumFrames)
        end
        
        function startTime = getStartTime(obj)
            startTime = obj.StartTime;
        end
        function obj = setStartTime(obj,startTime)
            obj.startTime = startTime;
        end
        function newVideoFilesCombined = plus(obj,videoFiletoAdd)
            newVideoFilesCombined=VideoFilesCombined(obj,videoFiletoAdd);
        end
        function ts = getTimestamps(obj)
            filename=obj.Name;
            startDateStr=filename(6:27);
            startDate=datetime(startDateStr,'Format',TimeFactory.getyyyyMMddhhmmssa);
            
            [~,remain] = strtok(filename(38:end),'@');
            StartFrame = str2double(strtok(remain,'@.-'))-1;
            if ~isnan(StartFrame)
                startlatency=seconds(StartFrame/obj.FrameRate);
                startDate=startDate+startlatency;
                warning(sprintf('Start for the videofile is adjusted %d second.\n',seconds(startlatency)));
            end
            tl=linspace(0,obj.Duration,obj.NumFrames);
            ts=timeseries(true(numel(tl),1),tl,'Name','IsActive');
            ts.TimeInfo.StartDate=startDate;
        end
        function ts = getTimeline(obj)
            ts=obj.getTimestamps;
            step=diff([ts.Time(1) ts.Time(end)])/numel(ts.Time);
            newtime=linspace(ts.Time(1),ts.Time(end),1000);
            ts=ts.resample(newtime);
            ts=ts.addsample('Data',false,'Time',ts.Time(1)-step);
            ts=ts.addsample('Data',false,'Time',ts.Time(end)+step);
        end
        
        
    end
end

