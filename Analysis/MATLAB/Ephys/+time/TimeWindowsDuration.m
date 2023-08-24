classdef TimeWindowsDuration
    %TIMEWINDOWS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        TimeTable
    end

    methods
        function obj = TimeWindowsDuration(timeTable)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least
            % two datetime value columns: Start, Stop
            if ~istable(timeTable)
                if isstruct(timeTable)
                    timeTable=struct2table(timeTable);
                elseif istimetable(timeTable)
                    timeTable=timetable2table(timeTable);
                elseif ismatrix(timeTable)
                    if ~isempty(timeTable)
                        timeTable=array2table(timeTable,'VariableNames',{'Start','Stop'});
                    else
                        timeTable=cell2table(cell(0,2),'VariableNames',{'Start','Stop'});
                    end
                elseif isfolder(timeTable)
                    folder=timeTable;
                    try
                        evtlist=dir(fullfile(folder,'*.evt'));[~,idx]=sort(evtlist.datenum);
                        evtfile=fullfile(evtlist(idx(1)).folder,evtlist(idx(1)).name);
                        nevt=neuroscope.EventFile(evtfile);
                        timeTable=nevt.TimeWindowsDuration.TimeTable;
                    catch
                        l=logging.Logger.getLogger;
                        l.warning('Tried to get %s, but did not get.',evtfile)
                    end
                end
            end
            obj.TimeTable = timeTable;
        end
        function t = getTimeTable(this)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least
            % two datetime value columns: Start, Stop
            t=this.TimeTable;
        end
        function obj = mergeOverlaps(obj,minDurationBetweenEvents)
            if ~isduration(minDurationBetweenEvents)
                minDurationBetweenEvents=seconds(minDurationBetweenEvents);
            end
            t=obj.TimeTable;
            rest=[];
            temp=t(1,:);
            for iwin=2:height(t)
                win=t(iwin,:);
                % do this win overlap with the temp
                winStartIsInOrCloseToTemp= (win.Start-temp.Stop)<minDurationBetweenEvents;
                overlap=winStartIsInOrCloseToTemp;
                if overlap % merge into temp
                    if temp.Start>win.Start
                        temp.Start=win.Start;
                    end
                    if temp.Stop<win.Stop
                        temp.Stop=win.Stop;
                    end
                else
                    rest=[rest;temp];
                    temp=win;
                end
            end
            rest=[rest;temp];
            obj.TimeTable=rest;
        end

        function timeWindows = plus(thisTimeWindows,newTimeWindows)
            %METHOD1 Summary of this method goes here
            table1=[thisTimeWindows.TimeTable; newTimeWindows.TimeTable];
            table2=sortrows(table1,1);
            timeWindows=time.TimeWindowsDuration(table2);
        end
        function thisTimeWindows = minus(thisTimeWindows,newTimeWindows)
            %METHOD1 Summary of this method goes here
            newtt=newTimeWindows.TimeTable;
            for inew=1:height(newtt)
                event=newtt(inew,:);
                startnew=event.Start;
                stopnew=event.Stop;
                thisTimeWindows=thisTimeWindows.removeWindow([startnew, stopnew]);
            end
        end
        function thisTimeWindows=removeWindow(thisTimeWindows,n)
            thistt=thisTimeWindows.TimeTable;
            ii=1;
            for iold=1:height(thistt)
                event=thistt(iold,:);
                o(1)=event.Start;
                o(2)=event.Stop;
                if n(1)>=o(2)||n(2)<=o(1) % outside
                    Start(ii)=o(1); % do nothing
                    Stop(ii)=o(2);
                elseif n(2)>=o(2) % first one is inside
                    if n(1)<o(1)
                        ii=ii-1;
                    else
                        Start(ii)=o(1);
                        Stop(ii)=n(1);
                    end
                else
                    if n(1)<=o(1)
                        Start(ii)=n(2);
                        Stop(ii)=o(2);
                    else
                        Start(ii)=o(1);
                        Stop(ii)=n(1);
                        ii=ii+1;
                        Start(ii)=n(2);
                        Stop(ii)=o(2);
                    end
                end
                ii=ii+1;
            end
            Start=Start';
            Stop=Stop';
            thisTimeWindows.TimeTable= table(Start,Stop);
        end


        function ax=plotHist(obj, ax, color)
            if ~exist('ax','var')
                ax=gca;
            end
            if ~exist('color','var')
                color=[0 0 0];
            end
            tt=table2array(obj.TimeTable);
            dur=tt(:,2)-tt(:,1);
            histogram(dur,'FaceColor', color);
            dim=[.4 ax.Position(2)+ax.Position(4)/3 .2 .2];
            annotation('textbox',dim,'String', [num2str(round(seconds(sum(dur)))) ' s'] ,...
                'FitBoxToText','on','LineStyle','none'),
            ylabel('Count')
        end
        function ax=plotScatter(obj, ax,color)
            if ~exist('ax','var')
                ax=gca;
            end
            if ~exist('color','var')
                color=[0 0 0];
            end
            tt=seconds(table2array(obj.TimeTable));
            dur=tt(:,2)-tt(:,1);
            s=scatter( hours(seconds(mean(tt,2))),rand(size(dur)),dur*10,color,'filled');
            alpha(.5)
            legend (s,'5 sec')
        end

        function file=saveForClusteringSpyKingCircus(obj,file)
            t=table2array(obj.TimeTable);
            if isduration(t)
                timeMs=seconds(t)*1000;
            else
                timeMs=t*1000;
            end
            if exist('file','var')
                if isfolder(file)
                    file=fullfile(file,'dead.txt');
                end
            end
            writematrix(timeMs,file,'Delimiter',' ');
        end
        function []=saveForNeuroscope(obj, pathname, type)
            if nargin>2
                type=upper(type(1));
            else
                type='R';
            end
            filename1=sprintf('*.%s*.evt',type);
            files = dir(fullfile(pathname,filename1));
            if isempty(files)
                fileN = 1;
            else
                %set file index to next available value\
                pat = sprintf('.%s[0-9].',type);
                fileN = 0;
                for ii = 1:length(files)
                    token  = regexp(files(ii).name,pat);
                    val    = str2double(files(ii).name(token+2:token+4));
                    fileN  = max([fileN val]);
                end
                fileN = fileN + 1;
            end
            tokens=split(pathname,filesep);
            filename=tokens{end};
            fname1=sprintf('%s%s%s.%s%02d.evt',pathname,filesep,filename,type,fileN);
            fid = fopen(fname1,'w');
            if fid~=-1
                % convert detections to milliseconds
                T= obj.TimeTable;
                start=seconds(T.Start)*1000;
                stop=seconds(T.Stop)*1000;
                fprintf(1,'Writing event file ...\n');
                for ii = 1:size(start,1)
                    fprintf(fid,'%9.1f\tStart\n',start(ii));
                    fprintf(fid,'%9.1f\tStop\n',stop(ii));
                end
                fclose(fid);
            else
                logging.Logger.getLogger.error('Invalid file name %s',fname1)
            end
        end
        function obj=getReverse(obj,length)
            % convert detections to milliseconds
            T= obj.TimeTable;
            Start=.001;
            Stop=[];
            start=T.Start;
            stop=T.Stop;
            for iwin=1:numel(start)
                Stop=[Stop; start(iwin)];
                Start=[Start; stop(iwin)];
            end
            Stop=[Stop; seconds(length)];
            T=table(Start,Stop);
            obj.TimeTable=T;
        end
        function arr=getArrayForBuzcode(obj)
            T=obj.TimeTable;
            start=seconds(T.Start);
            stop=seconds(T.Stop);
            arr=[start stop];
        end
    end
end

