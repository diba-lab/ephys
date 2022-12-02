classdef SpikeUnitLFP < neuro.spike.SpikeUnit
    %SPIKEUNITLFP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        LFP
    end
    
    methods
        function obj = SpikeUnitLFP(spikeUnit, LFP)
            %SPIKEUNITLFP Construct an instance of this class
            %   Detailed explanation goes here
            fnames=fieldnames(spikeUnit);
            for ifn=1:numel(fnames)
                fname=fnames{ifn};
                obj.(fname)=spikeUnit.(fname);
            end
            obj.LFP = LFP;
        end
        
        function phases = getPhases(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=obj.getTimesInSecZT;
            lfp=obj.LFP;
            lfp1=lfp.getBandpassFiltered(freq);
            phases=lfp1.getHilbertPhase;
            tZT=phases.getTimeInterval.getTimePointsInSecZT;
            srate=phases.getTimeInterval.getSampleRate;
            phaseres=nan(1,numel(times));
            ies=nan(1,numel(times));
            f = waitbar(0,'1','Name','Phases of the spikes are being calculated.');
            a= round(linspace(1,numel(times),21));
            for isp=1:numel(times)
                t=times(isp);
                [M,I]=min(abs(t-tZT));
                if M<=1/srate
                    phaseres(isp)=phases.Values(I);
                    ies(isp)=I;
                end
                % Update waitbar and message
                if ismember(isp,a)
                    waitbar(isp/numel(times),f, ...
                        sprintf('#spikes: %d\t\t %.0f %%', ...
                        numel(times), isp/numel(times)*100));
                end
            end
            delete(f);
            t1=table(phaseres',ies',times,VariableNames={'Phase','IndexInLFPData','TimesInZtSec'});
            phases=neuro.phase.SpikePhases(t1, obj.Info);
        end
    end
end

