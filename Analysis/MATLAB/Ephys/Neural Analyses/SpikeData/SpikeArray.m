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
            spiketablet=obj.SpikeTable;
            ticd=obj.TimeIntervalCombined;
            st=spiketablet.SpikeTimes;
            sc=spiketablet.SpikeCluster;
            if nargin<2
                unitnumbers=unique(sc);
            end
            figurename=sprintf('Rasterplot %s-%s',seconds(st([1 end])/ticd.getSampleRate)+ticd.getStartTime);
            try close(figurename);catch,end
            figure('Name',figurename, 'Units','normalized','Position',[0 0 1 .2])
            for iunit=1:numel(unitnumbers)
                unitnumber=unitnumbers(iunit);
                idx=ismember(sc,unitnumber);
                stn=st(idx);
                arr=seconds(double(stn)/ticd.getSampleRate)+ticd.getStartTime;
                s1=scatter(arr,ones(size(arr))*iunit,20,[0 0 0],'filled');
                hold on
                s1.MarkerEdgeAlpha=.1;
                s1.MarkerFaceAlpha=.1;
            end
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
        function []=saveNeuroscopeSpikeFiles(obj,folder)
             obj.saveCluFile(folder)
        end
    end
    methods %interited

    end
end

