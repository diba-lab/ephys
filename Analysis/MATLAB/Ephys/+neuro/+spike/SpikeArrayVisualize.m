classdef SpikeArrayVisualize < neuro.spike.SpikeArray
    %SPIKEARRAYVISUALIZE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = SpikeArrayVisualize(spikeArray)
            %SPIKEARRAYVISUALIZE Construct an instance of this class
            %   Detailed explanation goes here
            obj.SpikeTable=spikeArray.SpikeTable;
            obj.TimeIntervalCombined=spikeArray.TimeIntervalCombined;
            obj.ClusterInfo=spikeArray.ClusterInfo;
            obj.Info=spikeArray.Info;
        end

        function []=plot(obj,tfm)

            angles1=angle(tfm.matrix);
            t=tfm.timeIntervalCombined.getTimePointsInAbsoluteTimes;
            spiketablet=obj.SpikeTable;
            ticd=obj.TimeIntervalCombined;
            clustinfo=obj.ClusterInfo;
            st=spiketablet.SpikeTimes;
            sc=spiketablet.SpikeCluster;
            figurename=sprintf('Rasterplot %s-%s',ticd.getRealTimeFor(st([1 end])));
            try close(figurename);catch,end
            figure('Name',figurename, 'Units','normalized','Position',[0 0 .2 .3])
            clustinfo1=clustinfo;
            locations=unique(clustinfo1.location);
            colors=linspecer(numel(locations),'qualitative');
            phasemap(8);
            color=phasemap(8);
            for iunit=1:height(clustinfo1)
                unit=clustinfo1(iunit,:);
                idx=ismember(sc,unit.id);
                stn=st(idx);
                if ~isempty(stn)
                    arr=ticd.getRealTimeFor(stn);
                    clear c
                    for ipoint=1:numel(arr)
                        pnt=arr(ipoint);
                        idx=find(t<pnt,1,'last');
                        angle1=angles1(idx);
                        idx_color=round((angle1+pi)/2/pi*(size(color,1)-1))+1;
                        c(ipoint,:)=color(idx_color,:);
                    end
                    hold on
                    idx_location=ismember(locations,unit.location);
                    s=scatter(arr,ones(size(arr))*iunit,ones(size(arr))*30,c,'|');
                    s.LineWidth=4;
                    s.MarkerEdgeAlpha=.8;
                    %                     p1=plot(arr,iunit...
                    %                         ,'Marker','|'...
                    %                         ,'LineWidth',2 ...
                    %                         ,'Color',colors(idx_location,:)...
                    %                         ,'MarkerSize',3,...
                    %                         'MarkerEdgeColor',colors(idx_location,:));
                    %                 s1=scatter(arr,ones(size(arr))*iunit,20,[0 0 0],'filled');
                    %                 s1.MarkerEdgeAlpha=.1;
                    %                 s1.MarkerFaceAlpha=.1;
                end
            end
            ax=gca;
            ax.YDir='reverse';
            ax.YTick=2:5:height(clustinfo1);
            ax.YTickLabel=clustinfo1.sh(ax.YTick);
            locs = find(diff(sign(angles1))>0);
            %             [~,locs]=findpeaks(angles1);
            t1=t(locs);
            for iline=1:numel(locs)
                xline(t1(iline));
            end
            phasebar('size',.15,'location','southeast');
        end
        function []=plotRaster(obj)
            spiketablet=obj.SpikeTable;
            ticd=obj.TimeIntervalCombined;
            clustinfo=obj.ClusterInfo;
            st=spiketablet.SpikeTimes;
            sc=spiketablet.SpikeCluster;
            figurename=sprintf('Rasterplot %s-%s',ticd.getRealTimeFor(st([1 end])));
            try close(figurename);catch,end
            figure('Name',figurename, 'Units','normalized','Position',[0 0 .2 .3])
            clustinfo1=clustinfo;
            locations=unique(clustinfo1.sh);
            colors=linspecer(numel(locations),'qualitative');

            for iunit=1:height(clustinfo1)
                unit=clustinfo1(iunit,:);
                idx=ismember(sc,unit.id);
                stn=st(idx);
                if ~isempty(stn)
                    arr=ticd.getRealTimeFor(stn);
                    hold on
                    idx_location=ismember(locations,unit.sh);
                    %                     s=scatter(arr,ones(size(arr))*iunit,ones(size(arr))*30,c,'|');
                    %                     s.LineWidth=2;
                    p1=plot(arr,iunit...
                        ,'Marker','|'...
                        ,'LineWidth',2 ...
                        ,'Color',colors(idx_location,:)...
                        ,'MarkerSize',3,...
                        'MarkerEdgeColor',colors(idx_location,:));
                    %                     s1=scatter(arr,ones(size(arr))*iunit,20,[0 0 0],'filled');
                    s1.MarkerEdgeAlpha=.1;
                    s1.MarkerFaceAlpha=.1;
                end
            end
            ax=gca;
            ax.YDir='reverse';
            ax.YTick=2:5:height(clustinfo1);
            ax.YTickLabel=clustinfo1.sh(ax.YTick);
        end
    end
end

