classdef TimeSeriesZScored < neuro.basic.TimeSeries
    %TIMESERIESZSCORED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TimeSeriesZScored(data,sampleRate)
            %TIMESERIESZSCORED Construct an instance of this class
            %   Detailed explanation goes here
            obj.Values= data;
            obj.SampleRate=sampleRate;
        end
        
        function timeWindowsDuration = getTimeWindowsAboveThreshold(obj,threshold)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            val=obj.Values(1:(end-1));
            abovePoints=[0 val 0]>threshold;
            edges=diff(abovePoints);
            start=find(edges==1)'/obj.SampleRate-2.5*1e-3;
            stop=find(edges==-1)'/obj.SampleRate+2.5*1e-3;
            t1=array2table(seconds([start stop]-1*1e-3), ...
                VariableNames={'Start','Stop'});
            timeWindowsDuration= time.TimeWindowsDuration(t1);
        end
    end
end

