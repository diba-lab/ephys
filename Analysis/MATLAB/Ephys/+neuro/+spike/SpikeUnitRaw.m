classdef SpikeUnitRaw
    %SPIKEUNITRAW Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Id
        Times
        Info
        NumberOfSamples
        SampleRate
    end

    methods
        function obj = SpikeUnitRaw(id,times)
            %SPIKEUNITRAW Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                obj.Id=id;
                obj.Times=times;
            end
        end
        function obj = setInfo(obj,info)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Info=info;
        end
        function info=getInfo(obj,idx)
            info=sprintf(' ID:%d, nSpk:%d (of %d), Ch:%d',obj.Id,...
                numel(obj.Times(idx)),numel(obj.Times),obj.Channel);
        end
        function str=addInfo(obj,idx)
            str=obj.getInfo(idx);
            text(0,1,str,'Units','normalized','VerticalAlignment','bottom', ...
                'HorizontalAlignment','left');
        end
        function sut=plus(obj,track)
            sut=neuro.spike.SpikeUnitTracked(obj,track);
        end
        function str=tostring(obj)
            info=obj.Info;
            str=sprintf(['Id: %d, %d spikes\n %s\n Sh:%d, ' ...
                'Ch:%d\n Gr:%s\n %s\n %s\n Polarity:%.4f\n' ...
                ' frGiniCoef:%.4f\n frInstability:%.4f\n'], ...
                info.id, numel(obj.Times),...
                info.brainRegion{1}, ...
                info.sh, ...
                info.ch, ...
                info.group{1}, ...
                info.cellType{1}, ...
                info.synapticEffect{1}, ...
                info.polarity, ...
                info.firingRateGiniCoeff, ...
                info.firingRateInstability);
        end
        function fireRate = getFireRate(obj,timebininsec)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            timesInSamples=obj.Times;
            timesInSec=double(timesInSamples)/obj.SampleRate;
            endtimeinsec=double(obj.NumberOfSamples)/obj.SampleRate;
            N=histcounts(timesInSec,0:timebininsec:endtimeinsec)/...
                timebininsec;           
            fireRate=neuro.basic.TimeSeries(N,1/timebininsec); %#ok<*CPROPLC>
        end
    end
end

