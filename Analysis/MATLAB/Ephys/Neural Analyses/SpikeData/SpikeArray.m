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
        function []=plot(obj,unitnumbers)
            colors=linspecer(32);
            spiketablet=obj.SpikeTable;
            ticd=obj.TimeIntervalCombined;
            clustinfo=obj.ClusterInfo;
            st=spiketablet.SpikeTimes;
            sc=spiketablet.SpikeCluster;
            if nargin<2
                unitnumbers=unique(sc);
            end
            figurename=sprintf('Rasterplot %s-%s',seconds(st([1 end])/ticd.getSampleRate)+ticd.getStartTime);
            try close(figurename);catch,end
            figure('Name',figurename, 'Units','normalized','Position',[0 0 1 .2])
            clustinfo1=clustinfo(ismember(clustinfo.id,unitnumbers),:);
            for iunit=1:height(clustinfo1)
                unit=clustinfo1(iunit,:);
                idx=ismember(sc,unit.id);
                stn=st(idx);
                arr=seconds(double(stn)/ticd.getSampleRate)+ticd.getStartTime;
                hold on
                p1=plot(arr,iunit...
                    ,'Marker','|'...
                    ,'Color',colors(unit.ch+1,:)...
                    ,'MarkerSize',3,...
                    'MarkerEdgeColor',colors(unit.ch+1,:));
                %                 s1=scatter(arr,ones(size(arr))*iunit,20,[0 0 0],'filled');
                %                 s1.MarkerEdgeAlpha=.1;
                %                 s1.MarkerFaceAlpha=.1;
            end
            ax=gca;
            ax.YDir='reverse';
            ax.YTick=2:5:height(clustinfo1);
            ax.YTickLabel=clustinfo1.sh(ax.YTick);
        end
        function obj=getTimeInterval(obj,timeWindow)
            ticd = obj.TimeIntervalCombined;
            t(1)=ticd.convertDurationToDatetime(timeWindow(1));
            t(2)=ticd.convertDurationToDatetime(timeWindow(2));
            start=ticd.getStartTime;
            s(1)=seconds(t(1)-start)*ticd.getSampleRate;
            s(2)=seconds(t(2)-start)*ticd.getSampleRate;
            tbl=obj.SpikeTable;
            tbl((tbl.SpikeTimes<s(1))|(tbl.SpikeTimes>s(2)),:)=[];
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
    end
    methods %interited
        
    end
end

