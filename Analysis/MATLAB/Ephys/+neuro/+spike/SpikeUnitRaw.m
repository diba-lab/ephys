classdef SpikeUnitRaw
    %SPIKEUNITRAW Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Id
        TimesInSamples
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
                obj.TimesInSamples=times;
            end
        end
        function obj = setInfo(obj,info)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Info=info;
        end
        function ns = getNumberOfSpikes(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ns=numel(obj.TimesInSamples);
        end
        function info=getInfo(obj,idx)
            info=sprintf(' ID:%d, nSpk:%d (of %d), Ch:%d',obj.Id,...
                numel(obj.TimesInSamples(idx)),numel(obj.TimesInSamples),obj.Channel);
        end
        function info=getInfoTable(obj)
            if ~isempty(obj.Info)
                info=obj.Info;
            else
                info=table(obj.Id,VariableNames={'Id'});
            end
        end
        function str=addInfo(obj,idx)
            str=obj.getInfo(idx);
            text(0,1,str,'Units','normalized','VerticalAlignment','bottom', ...
                'HorizontalAlignment','left');
        end
        function sutl=plus(obj,positionOrLfp)
            if isa(positionOrLfp,"position.PositionData")
                sutl=neuro.spike.SpikeUnitTracked(obj,positionOrLfp);
            else
                sutl=neuro.spike.SpikeUnitLFP(obj,positionOrLfp);
            end
        end
        function str=tostring(obj)
            info=obj.Info;
            str=sprintf(['Id: %d\n' ...
                '%d spikes\n' ...
                '\n' ...
                '%s\n' ...
                'Sh: %d\n' ...
                'Ch: %d\n' ...
                '\n' ...
                'Gr: %s\n' ...
                '%s\n' ...
                '%s\n' ...
                '\n' ...
                'Polarity: %.3f\n' ...
                'frGiniCoef: %.3f\n' ...
                'frInstability: %.3f\n'], ...
                info.id, numel(obj.TimesInSamples),...
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
            timesInSamples=obj.TimesInSamples;
            timesInSec=double(timesInSamples)/obj.SampleRate;
            endtimeinsec=double(obj.NumberOfSamples)/obj.SampleRate;
            N=histcounts(timesInSec,0:timebininsec:endtimeinsec)/...
                timebininsec;           
            fireRate=neuro.basic.TimeSeries(N,1/timebininsec); %#ok<*CPROPLC>
        end
    end
end

