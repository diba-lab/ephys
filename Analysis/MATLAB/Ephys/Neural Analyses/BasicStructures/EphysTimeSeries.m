classdef EphysTimeSeries < Oscillation
    %EPHYSTIMESERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        Name
    end
    
    methods
        function obj = EphysTimeSeries(values,sampleRate,name)
            %EPHYSTIMESERIES Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@Oscillation(values,sampleRate);

            if exist('name','var')
                obj.Name=name;
            else
                obj.Name='';
            end
        end
    end
    methods
        function ets = setName(ets,name)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
                ets.Name=name;
        end
        function ets = getName(ets,name)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
                ets.Name=name;
        end
        function hist = plotHistogram(ets)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            histogram(ets.getValues);
            ax=gca;
            ax.XLim=[5 10];
            xlabel('Frequency (Hz)');
            ylabel('Count');
        end
    end
end

