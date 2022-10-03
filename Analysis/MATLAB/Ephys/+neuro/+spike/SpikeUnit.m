classdef SpikeUnit
    %SPIKEUNIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Id
        Times
        TimeIntervalCombined
        Info
    end
    
    methods
        function obj = SpikeUnit(spikeId,spikeTimes,timeIntervalCombined)
            %SPIKEUNIT Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==3
                obj.Id = spikeId;
                obj.Times=spikeTimes;
                obj.TimeIntervalCombined=timeIntervalCombined;
            elseif nargin==1 && isa(spikeId,"neuro.spike.SpikeUnit")
                obj.Id=spikeId.Id;
                obj.Times=spikeId.Times;
                obj.Info=spikeId.Info;
                obj.TimeIntervalCombined=spikeId.TimeIntervalCombined;
            end
        end
        
        function timesnew = getAbsoluteSpikeTimes(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ticd=obj.TimeIntervalCombined;
            timesnew=ticd.getRealTimeFor(double(obj.Times));
        end
        function times = getTimes(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=neuro.time.Sample(obj.Times, obj.TimeIntervalCombined.getSampleRate);
        end
        function obj = setInfo(obj,info)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Info=info;
        end
        function fireRate = getFireRate(obj,timebininsec)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            TimeBinsInSec=timebininsec;
            timesInSamples=obj.Times;
            til=obj.TimeIntervalCombined.getTimeIntervalList;
            endtimeinseclast=0;
            ticdnew=neuro.time.TimeIntervalCombined;
            for iti=1:til.length
                ti=til.get(iti);
                endtimeinsec=seconds(ti.getEndTime-ti.getStartTime);
                timesInSec=double(timesInSamples)/ti.getSampleRate-endtimeinseclast;
                endtimeinseclast=endtimeinseclast+endtimeinsec;
                N=histcounts(timesInSec,0:TimeBinsInSec:endtimeinsec)/TimeBinsInSec;
                if iti==1
                    Nres=N;
                else
                    Nres=[Nres N];
                end
                tinew=neuro.time.TimeIntervalZT(ti.getStartTime+seconds(TimeBinsInSec/2),1/(TimeBinsInSec),numel(N),ti.getZeitgeberTime);
                ticdnew=ticdnew+tinew;
            end
            fireRate=neuro.basic.Channel(num2str(obj.Id),Nres,ticdnew); %#ok<*CPROPLC>
        end
        function info=getInfo(obj,idx)
            
            info=sprintf(' ID:%d, nSpk:%d (of %d), Ch:%d',obj.Id,...
                numel(obj.Times(idx)),numel(obj.Times),obj.Channel);
            
        end
        function str=addInfo(obj,idx)
            str=obj.getInfo(idx);
            text(0,1,str,'Units','normalized','VerticalAlignment','bottom','HorizontalAlignment','left');
            
        end
        function sut=plus(obj,track)
            sut=neuro.spike.SpikeUnitTracked(obj,track);
        end
    end
end

