classdef SpikeArray < SpikeNeuroscope
    %SPIKEARRAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SpikeTable
        TimeIntervalCombined
        ClusterInfo
    end
    
    methods
        function obj = SpikeArray(spikeClusters,spikeTimes)
            %SPIKEARRAY Construct an instance of this class
            %   spiketimes should be in Timestamps.
            tablearray=horzcat( spikeTimes, double(spikeClusters));
            obj.SpikeTable=array2table(tablearray,'VariableNames',{'SpikeTimes','SpikeCluster'});
        end
        
        function obj = getSpikeArrayWithAdjustedTimestamps(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            st=obj.SpikeTable;
            spiketimessample=st.SpikeTimes;
            ticd=obj.TimeIntervalCombined;
            adjustedspiketimessample=ticd.adjustTimestampsAsIfNotInterrupted(spiketimessample);
            obj.SpikeTable.SpikeTimes=adjustedspiketimessample;
        end
        function obj=setTimeIntervalCombined(obj,ticd)
            obj.TimeIntervalCombined=ticd;
        end
        function obj=setClusterInfo(obj,ci)
            obj.ClusterInfo=ci;
        end
        function tbl=getspikeIDs(obj)
            spikeIDs=unique(obj.SpikeTable.SpikeCluster);
            for iid=1:numel(spikeIDs)
                spikeid=spikeIDs(iid);
                spikecounts(iid)=sum(obj.SpikeTable.SpikeCluster==spikeid);
            end
            tbl=array2table(horzcat(spikeIDs,spikecounts'),'VariableNames',{'ID','count'});
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
        function obj=getTimeInterval(obj,timeWindow)
            ticd = obj.TimeIntervalCombined;
            if isduration(timeWindow)
                t(1)=ticd.convertDurationToDatetime(timeWindow(1));
                t(2)=ticd.convertDurationToDatetime(timeWindow(2));
            else
                t=timeWindow;
            end
            s=ticd.getSampleFor(t);
            tbl=obj.SpikeTable;
            tbl((tbl.SpikeTimes<s(1))|(tbl.SpikeTimes>=s(2)),:)=[];
            obj.SpikeTable=tbl;
        end
        function spikeUnits=getSpikeUnits(obj)
            spikeIDs=unique(obj.SpikeTable.SpikeCluster);
            tbl=obj.SpikeTable;
            ci=obj.ClusterInfo;
            for isid=1:numel(spikeIDs)
                spikeId=spikeIDs(isid);
                aci=ci(ci.id==spikeId,:);
                spktimes=tbl.SpikeTimes(tbl.SpikeCluster==spikeId);
                spikeUnits(isid)=SpikeUnit(spikeId,spktimes,obj.TimeIntervalCombined,...
                    aci.amp,aci.ch,aci.fr,aci.group,aci.n_spikes,aci.purity);
            end
        end
        function spikeUnit=getSpikeUnit(obj,spikeId)
            tbl=obj.SpikeTable;
            ci=obj.ClusterInfo;
            aci=ci(ci.id==spikeId,:);
            spktimes=tbl.SpikeTimes(tbl.SpikeCluster==spikeId);
            spikeUnit=SpikeUnit(spikeId,spktimes,obj.TimeIntervalCombined,...
                aci.amp,aci.ch,aci.fr,aci.group,aci.n_spikes,aci.purity);
        end
        function []=saveNeuroscopeFiles(obj,folder,filename)
            if ~exist('filename','var')
                filename='neuro';
            end
            if ~exist('folder','var')
                folder='.';
            end
            obj.saveCluFile(fullfile(folder,[filename  '.clu.0']),obj.SpikeTable.SpikeCluster);
            obj.saveResFile(fullfile(folder,[filename  '.res.0']),obj.SpikeTable.SpikeTimes);
        end
        function [sa]=plus(obj,sa)
            shift=max(obj.ClusterInfo.id);
            sa.ClusterInfo.id=sa.ClusterInfo.id+shift;
            sa.SpikeTable.SpikeCluster=sa.SpikeTable.SpikeCluster+shift;
            sa.ClusterInfo=sortrows([obj.ClusterInfo; sa.ClusterInfo],{'group','sh','ch'});
            
            sa.SpikeTable=sortrows([obj.SpikeTable; sa.SpikeTable],{'SpikeTimes'});
        end
        function [obj]=setShank(obj,shankno)
            obj.ClusterInfo.sh=ones(height(obj.ClusterInfo),1)*shankno;
        end
        function [obj]=setLocation(obj,location)
            str=cell(height(obj.ClusterInfo),1);
            str(:)=location;
            obj.ClusterInfo.location=str;
        end
        function [obj]=sort(obj,by)
            %by={'group','sh','ch'}
            obj.ClusterInfo=sortrows(obj.ClusterInfo,by);
        end
    end
    methods %interited
        
    end
end

