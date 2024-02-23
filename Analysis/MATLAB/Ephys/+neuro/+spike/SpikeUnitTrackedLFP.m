classdef SpikeUnitTrackedLFP < ...
        neuro.spike.SpikeUnitLFP &...
        neuro.spike.SpikeUnitTracked
    %SPIKEUNITTRACKEDLFP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        combinedTable
        thetaPhasePrecession
    end
    
    methods
        function obj = SpikeUnitTrackedLFP(spikeUnitLFP,positionData)
            %SPIKEUNITTRACKEDLFP Construct an instance of this class
            %   Detailed explanation goes here
            fnames=fieldnames(spikeUnitLFP);
            for ifn=1:numel(fnames)
                fname=fnames{ifn};
                obj.(fname)=spikeUnitLFP.(fname);
            end
            sut=neuro.spike.SpikeUnitTracked(spikeUnitLFP,positionData);
            fnames=fieldnames(sut);
            for ifn=1:numel(fnames)
                fname=fnames{ifn};
                obj.(fname)=sut.(fname);
            end
            if numel(sut.TimesInSamples)>50
                obj.thetaPhasePrecession=obj.getThetaPhasePrecession;
                obj.combinedTable=[obj.thetaPhasePrecession.Position ...
                    obj.thetaPhasePrecession.PolarData];
            end
        end
        
        function precession = getThetaPhasePrecession(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            phases= obj.getPhases();
            [position, sample]=obj.PositionData.getPositionForTimes( ...
                obj.getAbsoluteSpikeTimes);
            zt=seconds(obj.getTimesZT);
            sample=reshape(sample,[],1);
            t1=array2table(sample,"VariableNames","SampleInPositionDataValues");
            t2=array2table(zt,"VariableNames","ZeitgeberTimeSeconds");

            position1=[position t2 t1];
            precession=neuro.phase.PhasePrecession(phases,position1);
        end
        function [] = plot(obj,axs)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            axes(axs(1));
            colors=colororder;
            tbl=obj.combinedTable;
            ph=obj.thetaPhasePrecession;
            ph1=ph.PolarData.Phase;
            cidx=round(normalize(ph1,"range",[1 256]));
            hsv=colormap("hsv");
            colorcode=hsv(cidx,:);
            obj.plotOnTrack3D(colorcode);
            axis normal
            view(0,0)
            axes(axs(2));
            s=scatter(tbl.X,tbl.Phase,[],colorcode,"filled");
            s.MarkerFaceAlpha=.5;
            axes(axs(3));
            ph.plotPrecession(colorcode);
            axes(axs(4));
            ph.plotHist(colors(1,:));
            axes(axs(5));
            ph.plotStats;
            linkaxes(axs,'x');
        end
    end
end

