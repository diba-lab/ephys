classdef SpikeUnitLFP < neuro.spike.SpikeUnit
    %SPIKEUNITLFP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        LFP
        ThetaPhases
    end
    
    methods
        function obj = SpikeUnitLFP(spikeUnit, LFP)
            %SPIKEUNITLFP Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                fnames=fieldnames(spikeUnit);
                for ifn=1:numel(fnames)
                    fname=fnames{ifn};
                    obj.(fname)=spikeUnit.(fname);
                end
                obj.LFP = LFP;
                lfp=obj.LFP;
                lfp1=lfp.getBandpassFiltered([5 11]);
                obj.ThetaPhases=lfp1.getHilbertPhase;
            end
        end
        
        function phases = getPhases(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            times=seconds(obj.getTimesZT);
            phases=obj.ThetaPhases;
            tZT=seconds(phases.getTimeInterval.getTimePointsZT);
            srate=phases.getTimeInterval.getSampleRate;
            phaseres=nan(1,numel(times));
            ies=nan(1,numel(times));
%             f = waitbar(0,'1','Name','Phases of the spikes are being calculated.');
%             a= round(linspace(1,numel(times),21));
            for isp=1:numel(times)
                t=times(isp);
                [M,I]=min(abs(t-tZT));
                if M<1/srate
                    phaseres(isp)=phases.Values(I);
                    ies(isp)=I;
                end
                % Update waitbar and message
%                 if ismember(isp,a)
%                     waitbar(isp/numel(times),f, ...
%                         sprintf('#spikes: %d\t\t %.0f %%', ...
%                         numel(times), isp/numel(times)*100));
%                 end
            end
%             delete(f);
            phaseres=reshape(phaseres,[],1);
            ies=reshape(ies,[],1);
            times=reshape(times,[],1);
            t1=table(phaseres,ies,times,VariableNames={'Phase', ...
                'IndexInLFPData','TimesInZtSec'});
            phases=neuro.phase.SpikePhases(t1, obj.Info);
        end
        function sutl=plus(obj, position)
            if isa(position,"position.PositionData")||...
                isa(position,"position.PositionData1D")
                sutl=neuro.spike.SpikeUnitTrackedLFP(obj, position);
            end
        end

    end
end

