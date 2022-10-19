classdef SpikeArray < neuro.spike.SpikeNeuroscope
    %SPIKEARRAY Summary of this class goes here
    %   Detailed explanation goes here

    properties
        SpikeTable
        TimeIntervalCombined
        ClusterInfo
        Info
    end

    methods
        function obj = SpikeArray(spikeClusters,spikeTimes)
            %SPIKEARRAY Construct an instance of this class
            %   spiketimes should be in Timestamps.
            if ~isa(spikeClusters,'neuro.spike.SpikeArray')
                tablearray=horzcat( spikeTimes, double(spikeClusters));
                obj.SpikeTable=array2table(tablearray,'VariableNames',{'SpikeTimes','SpikeCluster'});
            else
                obj.SpikeTable=spikeClusters.SpikeTable;
                obj.TimeIntervalCombined=spikeClusters.TimeIntervalCombined;
                obj.ClusterInfo=spikeClusters.ClusterInfo;
                obj.Info=spikeClusters.Info;
            end
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
        function print(obj,varargin)
            logger=logging.Logger.getLogger;
            colstrings=obj.tostring(varargin{:});
            for icountgroup=1:numel(colstrings)
                colstring=colstrings{icountgroup};
                logger.info(colstring);
            end
        end
        function colstrings=tostring(obj,varargin)
            logger=logging.Logger.getLogger;
            tbl=obj.ClusterInfo;
            if nargin>1
                idx=ismember(varargin,tbl.Properties.VariableNames);
                if ~all(idx)
                    logger.warning([varargin{~idx} ' is not a column in the table.' strjoin(tbl.Properties.VariableNames,', ')]);
                end
                countGroup=varargin(idx);
            else
                countGroup={'group','ch'};
            end
            colstrings=cell.empty(numel(countGroup),0);
            for icountgroup=1:numel(countGroup)
                countgroup=countGroup{icountgroup};
                col=unique(tbl.(countgroup));
                colStr=cell.empty(numel(col),0);
                for icol=1:numel(col)
                    uniqueelement=col(icol);
                    idx=ismember(tbl.(countgroup),uniqueelement);
                    if iscategorical(uniqueelement)
                        uniqueelementstr=char(uniqueelement);
                    elseif isnumeric(uniqueelement)
                        uniqueelementstr=num2str(uniqueelement);
                    elseif isstring(uniqueelement)
                        uniqueelementstr=char(uniqueelement);
                    else
                        uniqueelementstr=uniqueelement;
                    end
                    colStr{icol}=[uniqueelementstr '(' num2str(sum(idx)) ')'];
                end
                colstring=strcat(countgroup,': ',strjoin(colStr,', '));
                colstrings{icountgroup}=colstring;
            end
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
        %         function fr=getMeanFireRate(obj)
        %             sus=obj.getSpikeUnits;
        %             for isu=1:numel(sus)
        %                 su=sus(isu);
        %                 frs=su.getFireRate;
        %                 try
        %                     vals(isu,:)=frs.getValues;
        %                 catch
        %                 end
        %             end
        %             val_m=mean(vals,1);
        %             fr=Channel('Mean Over Units',val_m,frs.getTimeInterval);
        %         end
        function [frm, fre]=getMeanFireRateQuintiles(obj,nquintiles,timebininsec,order)
            sus=obj.getSpikeUnits;
            for isu=1:numel(sus)
                su=sus(isu);
                frs=su.getFireRate(timebininsec);
                try
                    vals1(isu,:)=frs.getValues;
                catch
                end
            end
            if ~exist('order','var')||isempty(order)
                vals=sort(vals1,1);
            else
                vals=vals1(order,:);
            end
            nunit=size(vals,1);
            qus=[round(quantile(1:nunit,nquintiles-1)) nunit];
            pre=1;
            for iquint=1:nquintiles
                idx=pre:qus(iquint);pre=qus(iquint)+1;
                thequint=vals(idx,:);
                themeanquint=mean(thequint,1);
                thesterrquint=std(thequint,1)/sqrt(size(thequint,1));
                frm{iquint}=neuro.basic.Channel(sprintf('Mean Over Units Quint, %d',iquint),...
                    themeanquint,frs.getTimeInterval);
                fre{iquint}=neuro.basic.Channel(sprintf('Mean Over Units Quint, %d',iquint),...
                    thesterrquint,frs.getTimeInterval);
            end
        end
        function [frm, fre]=getMeanFireRate(obj,timebinInSec)
            sus=obj.getSpikeUnits;
            for isu=1:numel(sus)
                su=sus(isu);
                frs=su.getFireRate(timebinInSec);
                try
                    vals(isu,:)=frs.getValues;
                catch
                end
            end
            themeanquint=mean(vals,1);
            thesterrquint=std(vals,1)/sqrt(size(vals,1));
            frm=neuro.basic.Channel(sprintf('Mean Over Units'),...
                themeanquint,frs.getTimeIntervalCombined);
            fre=neuro.basic.Channel(sprintf('Mean Over Units'),...
                thesterrquint,frs.getTimeIntervalCombined);

        end
        function frs=getFireRates(obj,timebininsec)
            sus=obj.getSpikeUnits;
            for isu=1:numel(sus)
                su=sus(isu);
                frs=su.getFireRate(timebininsec);
                try
                    vals(isu,:)=frs.getValues;
                catch
                end
            end
            frs=neuro.spike.FireRates(vals,[sus.Id],frs.getTimeIntervalCombined);
            frs.Info.TimebinInSec=timebininsec;
            frs.ClusterInfo=obj.ClusterInfo;
        end

        function obj=getTimeInterval(obj,timeWindow)
            if isdatetime(timeWindow)
                s=obj.TimeIntervalCombined.getSampleForClosest(timeWindow);
            elseif isduration(timeWindow)
                s=obj.TimeIntervalCombined.getSampleForClosest(obj.TimeIntervalCombined.getDate+timeWindow);
            end
            tbl=obj.SpikeTable;
            tbl((tbl.SpikeTimes<s(1))|(tbl.SpikeTimes>=s(2)),:)=[];
            tbl.SpikeTimes=tbl.SpikeTimes-s(1);
            obj.SpikeTable=tbl;
            obj.Info.TimeFrame=timeWindow;
            obj.TimeIntervalCombined=obj.TimeIntervalCombined.getTimeIntervalForTimes(timeWindow);
        end
        function spikeUnits=getSpikeUnits(obj,idx)
            tbl=obj.SpikeTable;
            ci=obj.ClusterInfo;
            if exist('idx','var') && ~isempty(idx)
                ci_sub=ci(idx,:);
            else
                ci_sub=ci;
            end
            for isid=1:height(ci_sub)
                aci=ci_sub(isid,:);
                spktimes=tbl.SpikeTimes(tbl.SpikeCluster==aci.id);
                spikeUnits(isid)=neuro.spike.SpikeUnit(aci.id,spktimes,obj.TimeIntervalCombined);
                spikeUnits(isid)=spikeUnits(isid).setInfo(aci);
            end
        end
        function obj=get(obj,varargin)
            selected=true(height(obj.ClusterInfo),1);
            if nargin==1
            elseif nargin==2&& (isnumeric(varargin{1})||islogical(varargin{1}))
                selected=varargin{1};
            else
                cluinf=obj.ClusterInfo;
                stringinterest={'location','group'};
                selected_arg=false(height(obj.ClusterInfo),1);
                for iarg=1:nargin-1
                    arg=varargin{iarg};
                    for iint=1:numel(stringinterest)
                        interest=stringinterest{iint};
                        if any(ismember(cluinf.(interest),arg))
                            selected_arg=selected_arg|ismember(cluinf.(interest),arg);
                        end
                    end
                end
                selected=selected&selected_arg;
            end
            tbl=obj.SpikeTable;
            obj.ClusterInfo=obj.ClusterInfo(selected,:);
            obj.SpikeTable=tbl(ismember(tbl.SpikeCluster,obj.ClusterInfo.id),:);
        end
        function pbe=getPopulationBurstEvents(obj)

        end
        function acg=getAutoCorrelogram(obj)
            sus=obj.getSpikeUnits;
            acg=neuro.spike.AutoCorrelogram(sus);
        end
        function []=saveNeuroscopeFiles(obj,folder,filename)
            if ~exist('filename','var')
                filename='neuro';
            end
            if ~exist('folder','var')
                folder='.';
            end
            obj.saveCluFile(fullfile(folder,[filename  '.clu.0']));
            obj.saveResFile(fullfile(folder,[filename  '.res.0']));
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
            str= repmat(location,height(obj.ClusterInfo),1);
            obj.ClusterInfo.location=str;
        end
        function [obj]=sort(obj,by)
            %by={'group','sh','ch'}
            obj.ClusterInfo=sortrows(obj.ClusterInfo,by);
        end
    end
    methods %inherited
        function st=getSpikeTimes(obj)
            st=obj.SpikeTable.SpikeTimes;
        end
        function sc=getSpikeClusters(obj)
            sc=obj.SpikeTable.SpikeCluster;
        end
    end
end

