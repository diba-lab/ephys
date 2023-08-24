classdef TimeWindowsSample <time.TimeWindows
    %TIMEWINDOWS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SampleTable
    end
    
    methods
        function obj = TimeWindowsSample(timeTable)
            %TIMEWINDOWS Construct an instance of this class
            %   Table should have at least 
            % two sample value columns: Start, Stop
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
            obj.SampleTable = timeTable;
        end
        function t = getDuration(obj,samplingRatePerSecond)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least 
            % two datetime value columns: Start, Stop
            t=obj.SampleTable;
            arr=table2array(t);
            t1=seconds(arr/samplingRatePerSecond);
            t=time.TimeWindowsDuration(t1);
        end
        function t = getTimeTable(this)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least 
            % two datetime value columns: Start, Stop
            t=this.TimeTable;
        end
        function obj = mergeOverlaps(obj,minSamplesBetweenWindows)
        end
        
        function timeWindows = plus(thisTimeWindows,newTimeWindows)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
        end
        function ax=plot(obj,ax)
        end
    end
end

