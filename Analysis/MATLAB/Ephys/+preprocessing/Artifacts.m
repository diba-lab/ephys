classdef Artifacts
    %ARTIFACTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Table
        Channel
        artifacts_freq
        Power
        Preprocess
    end
    
    methods
        function obj = Artifacts(preprocess,combinedBad,ch_ds,artifacts_freq,power)
            %ARTIFACTS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Table = combinedBad;
            obj.Channel = ch_ds;
            obj.artifacts_freq = artifacts_freq;
            obj.Power = power;
            obj.Preprocess = preprocess;
        end
        
        function outputArg = plot(obj,wind)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if exist('wind','var')
                st=obj.Channel.getTimeInterval.getStartTime;
                st.Hour=0;st.Minute=0;st.Second=0;
                wind=wind+st;
            end
            params=obj.Preprocess.getParameters;
            param_spec=params.Spectogram;
            freqs=[param_spec.FrequencyBands.start' param_spec.FrequencyBands.stop'];
            try close(1); catch, end;f=figure(1);f.Units='normalized';
            f.Position=[0.3600    0.2262    0.6400    0.5203];
            colors=linspecer(numel(obj.Power)+1);
            zs=obj.Channel.getZScored;
            subplot(1+numel(obj.Power),10,10);ax=gca;
            [N,edges]=histcounts(zs.getVoltageArray,40,'BinLimits',params.ZScore.PlotYLims);
            edges(1)=[];
            centers=edges-(edges(2)-edges(1))/2;
            barh(ax,centers,N,'BarWidth',1,'FaceColor',colors(1,:));
            ax.YLim=params.ZScore.PlotYLims;

            subplot(1+numel(obj.Power),10,1:9);ax=gca;
            zs.plot;hold on;ax=gca;
            obj.Table.plot(ax)
            ax.YLim=params.ZScore.PlotYLims;
            if exist('wind','var'), ax.XLim=wind;end
            yline( params.ZScore.Threshold(1));
            yline( params.ZScore.Threshold(2));
            for ifreq=1:numel(obj.Power)
                thePower=obj.Power{ifreq};
                zs=thePower.getZScored;
                subplot(1+numel(obj.Power),10,(10+ifreq*10));ax=gca;
                th=[params.Spectogram.ZScore.Threshold.start(ifreq)...
                    params.Spectogram.ZScore.Threshold.stop(ifreq)];
                ylim=[params.Spectogram.ZScore.PlotYLims.start(ifreq)...
                    params.Spectogram.ZScore.PlotYLims.stop(ifreq)];
                [N,edges]=histcounts(zs.getVoltageArray,40,'BinLimits',ylim);
                edges(1)=[];
                centers=edges-(edges(2)-edges(1))/2;
                barh(ax,centers,N,'BarWidth',1,'FaceColor',colors(1+ifreq,:));
                ax.YLim=ylim;
                yline( th(1));
                yline( th(2));         
                subplot(1+numel(obj.Power),10,((1:9)+ifreq*10));ax=gca;
                zs.plot;hold on;
                ax.YLim=ylim;
                if exist('wind','var'), ax.XLim=wind;end
                yline( th(1));
                yline( th(2));
                theartifacts_freq=obj.artifacts_freq{ifreq};
                theartifacts_freq.plot()
                ylabel(sprintf('Power (zscored) %d-%d Hz',freqs(ifreq,:)))
            end
        end
        function saveBadTimesForClustering(obj)
            t=obj.Table;
            t.saveForClusteringSpyKingCircus('dead.txt');
        end
    end
end

