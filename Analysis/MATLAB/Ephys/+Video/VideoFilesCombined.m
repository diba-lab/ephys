classdef VideoFilesCombined < Timelined
    %VIDEOFILESCOMBINED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        videoFiles
    end
    
    methods
        function newobj = VideoFilesCombined(varargin)
            %OPENEPHYSRECORDSCOMBINED Construct an instance of this class
            videoFiles=CellArrayList();
            for iArgIn=1:nargin
                videoFile=varargin{iArgIn};
                assert(isa(videoFile,'VideoFile'));
                videoFiles.add(videoFile);
            end
            newobj.videoFiles=videoFiles;
        end
        
        function obj = plus(obj,varargin)
             for iArgIn=1:(nargin-1)
                videoFile=varargin{iArgIn};
                assert(isa(videoFile,'VideoFile'));
                obj.videoFiles.add(videoFile);
            end
        end
        function tls = getTimeline(obj)
            iter=obj.getIterator();
            tls=[];
            i=1;
            while(iter.hasNext)
                aVideoFile=iter.next();
                tl=aVideoFile.getTimeline();
                tls{i}=tl;i=i+1;
            end
        end
        function evts = getEvents(obj)
            evts=obj;
        end
        function [] = preview(obj,timewindow)
            iter=obj.getIterator;
            while iter.hasNext
                vidfile=iter.next;
                ts=vidfile.getTimestamps;
                last=ts.TimeInfo.StartDate+seconds(ts.Time(end));
                first=ts.TimeInfo.StartDate+seconds(ts.Time(1));
                if (timewindow(2)<last)&&(timewindow(1)>first)
                    timewindowsec=seconds(timewindow-ts.TimeInfo.StartDate);
                    starttime=timewindowsec(1);
                    endtime=timewindowsec(2);
                    startFrame=find(ts.Time>=starttime,1,'first');
                    endFrame=find(ts.Time>=endtime,1,'first');
                    frames=vidfile.read([startFrame endFrame]);
                    implay(frames,vidfile.FrameRate*8)
                    fprintf('%s, %.1f-%.1f\n',vidfile.Name, starttime,endtime);
                    return
                end
            end
        end
        
    end
    
    methods (Access=private)
        function iterator=getIterator(obj)
            iterator=obj.videoFiles.createIterator;
        end
    end

end

