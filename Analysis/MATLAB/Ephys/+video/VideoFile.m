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
            file1=dir(fullfile(obj.Path,'*.csv'));
            file2=file1(contains({file1.name},'time',IgnoreCase=true));
            file3=file2(contains({file2.name},name,IgnoreCase=true));
            if isempty(file3)
                prompt = {'StartTime:','ZeitgeberTime'};
                dlgtitle = 'Time interval';
                dims = [1 25];
                try
                    a=split(name,{'-Cam'});
                    file3=file1(contains({file1.name},[a{1} '.csv'],IgnoreCase=true));
                    filenameres=fullfile(file3.folder,file3.name);
                    cell1=readcell(filenameres);
                    time1=datetime(cell1{1,12},'InputFormat','uuuu-MM-dd hh.mm.ss.SSS a', ...
                        "Format","uuuu-MM-dd HH:mm:ss.SSS");
                catch
                    time1="now";
                end
                time1=datetime(time1,"Format","uuuu-MM-dd HH:mm:ss.SSS");
                definput = {datestr(time1,'yyyy-mm-dd HH:MM:SS.FFF'),'08:00'};
                answer = inputdlg(prompt,dlgtitle,dims,definput);
                startTime=datetime(answer{1},"Format","uuuu-MM-dd HH:mm:ss.SSS");
                zt=duration(answer{2},"Format","hh:mm");
                ti=neuro.time.TimeIntervalZT(startTime,obj.FrameRate,obj.NumFrames,zt);
                ti.saveTable(fullfile(obj.Path,[name '.time.csv']));
            else
                ti=neuro.time.TimeIntervalCombined(fullfile(file3.folder,file3.name));
            end
            obj.StartTime=ti.getStartTime;
        end
        
        function startTime = getStartTime(obj)
            startTime = obj.StartTime;
        end
        function obj = setStartTime(obj,startTime)
            obj.startTime = startTime;
        end
        function returnedval = plus(obj,add1)
            if isa(add1,'video.VideoFile')
                newVideoFilesCombined=VideoFilesCombined(obj,add1);
            elseif isa(add1,'video.DLCPositionEstimationFile')
                returnedval=video.VideoPlusPosition(obj,add1);
            end
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

