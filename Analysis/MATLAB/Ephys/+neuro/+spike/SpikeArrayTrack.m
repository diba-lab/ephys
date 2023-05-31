classdef SpikeArrayTrack < neuro.spike.SpikeArray
    %SPIKEARRAYTRACK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Position
    end
    
    methods
        function obj = SpikeArrayTrack(spikeArray,positionData)
            %SPIKEARRAYTRACK Construct an instance of this class
            %   Detailed explanation goes here
            fnames=fieldnames(spikeArray);
            for ifn=1:numel(fnames)
                fname=fnames{ifn};
                obj.(fname)=spikeArray.(fname);
            end
            obj.Position=positionData;
            obj.SpikeTableInSamples=[obj.SpikeTableInSamples obj.getPositions];
        end
        
        function [positions] = getPositions(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes hereobj.
            pos=obj.Position;
            pt=seconds(pos.time.getTimePointsZT)';
            sts=seconds(obj.getSpikeTimesZT);
            % Create a KDTree object from pt
            tree = KDTreeSearcher(pt);
            % Find the indices of the closest values in pt for each value
            % in sts
            locinpos = knnsearch(tree, sts);
            threshold=max(1./[obj.TimeIntervalCombined.getSampleRate ...
                        pos.time.getSampleRate]);
            locinpos(abs(sts - pt(locinpos)) > threshold) = NaN;
            positions=array2table(nan(length(sts),3), ...
                VariableNames=pos.data.Properties.VariableNames);
            % for isp=1:numel(sts)
            %     st=sts(isp);
            %     [g, idx]=min(abs(st-pt));
            %     if g<max(1./[obj.TimeIntervalCombined.getSampleRate ...
            %             pos.time.getSampleRate])
            %         locinpos(isp)=idx;
            %     end
            % end
            idxvalid=~isnan(locinpos);
            positions(idxvalid,:)=pos.data(locinpos(idxvalid),:);
        end
        function [] = plotFiringRates(obj,axs)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            fr=obj.getFireRates(.1).getFilteredGaussian(1);
            axs1=fr.plotFireRates(axs(1:3));
%             axes(axs(4));ax4=gca;
%             p=obj.Position.plotX;
%             p.LineWidth=1.5;col1=colororder; p.Color=col1(2,:);
            linkaxes(axs1,'x');
        end
    end
end

