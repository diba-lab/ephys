classdef EphysTimeSeries < neuro.basic.Oscillation
    %EPHYSTIMESERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        Name
        Info
        Time
    end
    
    methods
        function obj = EphysTimeSeries(values,sampleRate,time,name)
            %EPHYSTIMESERIES Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@neuro.basic.Oscillation(values,sampleRate);

            if exist('name','var')
                obj.Name=name;
            else
                obj.Name='';
            end
            if exist('time','var')
                obj.Time=time;
            else
                obj.Time='';
            end
        end
    end
    methods
        function ets = setName(ets,name)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
                ets.Name=name;
        end
        function name = getName(ets)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
                name=ets.Name;
        end
        function ets = setInfo(ets,info)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
                ets.Info=info;
        end
        function info = getInfo(ets)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
                info=ets.Info;
        end
        function ets = getEphysTimeSeries(ets)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
        end
        
        function ets = plus(ets,etsnew)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ets.getSampleRate==etsnew.getSampleRate
                ets.Values=horzcat(ets.getValues, etsnew.getValues);
            else
                
                error('Sample Rates...')
            end
        end
        function plotHistogram(ets)
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

