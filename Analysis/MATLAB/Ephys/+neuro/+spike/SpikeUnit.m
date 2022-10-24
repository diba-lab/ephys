classdef SpikeUnit < neuro.spike.SpikeUnitRaw
    %SPIKEUNIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Time
    end
    
    methods
        function obj = SpikeUnit(spikeId,spikeTimes,timeIntervalCombined)
            %SPIKEUNIT Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==3
                obj.Id = spikeId;
                obj.TimesInSamples=spikeTimes;
                obj.Time=timeIntervalCombined;
            elseif nargin==1 && isa(spikeId,"neuro.spike.SpikeUnit")
                obj.Id=spikeId.Id;
                obj.TimesInSamples=spikeId.TimesInSamples;
                obj.Info=spikeId.Info;
                obj.Time=spikeId.Time;
            end
            obj.NumberOfSamples=obj.Time.getNumberOfPoints;
            obj.SampleRate=obj.Time.getSampleRate;
        end
        
        function timesnew = getAbsoluteSpikeTimes(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ticd=obj.Time;
            timesnew=ticd.getRealTimeFor(double(obj.TimesInSamples));
        end
        function times = getTimes(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=neuro.time.Sample(obj.TimesInSamples, ...
                obj.Time.getSampleRate);
        end
        function tpInSecZT = getTimesInSecZT(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            tpInSecZT=seconds(obj.getAbsoluteSpikeTimes- ...
                obj.Time.getZeitgeberTime);
        end
        function fireRate = getFireRate(obj,timebininsec)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            TimeBinsInSec=timebininsec;
            timesInSamples=obj.TimesInSamples;
            til=obj.Time.getTimeIntervalList;
            endtimeinseclast=0;
            ticdnew=neuro.time.TimeIntervalCombined;
            for iti=1:til.length
                ti=til.get(iti);
                endtimeinsec=seconds(ti.getEndTime-ti.getStartTime);
                timesInSec=double(timesInSamples)/ ...
                    ti.getSampleRate-endtimeinseclast;
                endtimeinseclast=endtimeinseclast+endtimeinsec;
                N=histcounts(timesInSec,0:TimeBinsInSec:endtimeinsec)/...
                    TimeBinsInSec;
                if iti==1
                    Nres=N;
                else
                    Nres=[Nres N];
                end
                tinew=neuro.time.TimeIntervalZT( ...
                    ti.getStartTime+seconds(TimeBinsInSec/2), ...
                    1/(TimeBinsInSec),numel(N),ti.getZeitgeberTime);
                ticdnew=ticdnew+tinew;
            end
            fireRate=neuro.basic.Channel(num2str(obj.Id),Nres,ticdnew); %#ok<*CPROPLC>
        end
        
    end
end

