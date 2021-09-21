classdef TimeWindowsSample <neuro.time.TimeWindows
    %TIMEWINDOWS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SampleTable
    end
    
    methods
        function obj = TimeWindowsSample(sampleTable)
            %TIMEWINDOWS Construct an instance of this class
            %   Table should have at least 
            % two sample value columns: Start, Stop
            if isstruct(sampleTable)
                sampleTable=struct2table(sampleTable);
            elseif ismatrix(sampleTable)
                if ~isempty(sampleTable)
                    sampleTable=array2table(sampleTable,'VariableNames',{'Start','Stop'});
                else
                    sampleTable=cell2table(cell(0,2), 'VariableNames',{'Start','Stop'});
                end
            end
            obj.SampleTable = sampleTable;
        end
        function t = getDuration(obj,samplingRatePerSecond)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least 
            % two datetime value columns: Start, Stop
            t=obj.SampleTable;
            arr=table2array(t);
            t1=seconds(arr/samplingRatePerSecond);
            t=neuro.time.TimeWindowsDuration(t1);
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

