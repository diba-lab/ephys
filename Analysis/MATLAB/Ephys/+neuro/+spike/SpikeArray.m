classdef SpikeArray < neuro.spike.SpikeNeuroscope
    %SPIKEARRAY Summary of this class goes here
    %   Detailed explanation goes here

    properties
        SpikeTableInSamples
        TimeIntervalCombined
        ClusterInfo
        Info
    end

    methods
        function obj = SpikeArray(spikeClusters,spikeTimes)
            %SPIKEARRAY Construct an instance of this class
            %   spiketimes should be in Timestamps.
            if nargin>0
                if ~isa(spikeClusters,'neuro.spike.SpikeArray')
                    tablearray=horzcat( spikeTimes, double(spikeClusters));
                    obj.SpikeTableInSamples=array2table(tablearray, ...
                        'VariableNames',{'SpikeTimes','SpikeCluster'});
                else
                    obj.SpikeTableInSamples=spikeClusters.SpikeTable;
                    obj.TimeIntervalCombined=spikeClusters.TimeIntervalCombined;
                    obj.ClusterInfo=spikeClusters.ClusterInfo;
                    obj.Info=spikeClusters.Info;
                end
            end
        end

        function obj = getSpikeArrayWithAdjustedTimestamps(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            st=obj.SpikeTableInSamples;
            spiketimessample=st.SpikeTimes;
            ticd=obj.TimeIntervalCombined;
            adjustedspiketimessample= ...
                ticd.adjustTimestampsAsIfNotInterrupted(spiketimessample);
            obj.SpikeTableInSamples.SpikeTimes=adjustedspiketimessample;
            if isa(ticd,'time.TimeIntervalCombined')
                ti=ticd.timeIntervalList.get(1);
            elseif isa(ticd,'time.TimeInterval')
                ti=ticd;
            end
            ti.NumberOfPoints=ticd.getNumberOfPoints;
            obj.TimeIntervalCombined=ti;
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
                    logger.warning([ ...
                        varargin{~idx} ...
                        ' is not a column in the table.' ...
                        strjoin(tbl.Properties.VariableNames,', ') ...
                        ]);
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
            spikeIDs=unique(obj.SpikeTableInSamples.SpikeCluster);
            for iid=1:numel(spikeIDs)
                spikeid=spikeIDs(iid);
                spikecounts(iid)=sum(obj.SpikeTableInSamples.SpikeCluster==spikeid);
            end
            tbl=array2table(horzcat(spikeIDs,spikecounts'), ...
                'VariableNames',{'ID','count'});
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
        function [frm, fre]=getMeanFireRateQuintiles(obj,nquintiles, ...
                timebininsec,order)
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
                frm{iquint}=neuro.basic.Channel( ...
                    sprintf('Mean Over Units Quint, %d',iquint),...
                    themeanquint,frs.getTimeInterval);
                fre{iquint}=neuro.basic.Channel( ...
                    sprintf('Mean Over Units Quint, %d',iquint),...
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
            su1=sus(1);frs=su1.getFireRate(timebininsec);
            vals=nan(numel(sus),size(frs.getValues,2));
            for isu=1:numel(sus)
                su=sus(isu);
                frs=su.getFireRate(timebininsec);
                try
                    vals(isu,:)=frs.getValues;
                catch
                end
            end
            frs=neuro.spike.FireRates(vals,[sus.Id], ...
                frs.getTimeIntervalCombined);
            frs.Info.TimebinInSec=timebininsec;
            frs.ClusterInfo=obj.ClusterInfo;
        end
        function frs=getFireRatesZScored(obj,timebininsec)
            sus=obj.getSpikeUnits;
            su1=sus(1);frs=su1.getFireRate(timebininsec);
            vals=nan(numel(sus),size(frs.getValues,2));
            for isu=1:numel(sus)
                su=sus(isu);
                frs=su.getFireRate(timebininsec);
                try
                    vals(isu,:)=zscore(frs.getValues,0,2);
                catch
                end
            end
            frs=neuro.spike.FireRates(vals,[sus.Id],frs.getTimeIntervalCombined);
            frs.Info.TimebinInSec=timebininsec;
            frs.ClusterInfo=obj.ClusterInfo;
        end
        function frs=getFireRatesZScoredRaw(obj,timebininsec)
            sus=obj.getSpikeUnits;
            su1=sus(1);
            sur1=neuro.spike.SpikeUnitRaw(su1.Id,su1.Times);
            sur1.Info=su1.Info;
            sur1.NumberOfSamples=su1.NumberOfSamples;
            sur1.SampleRate=su1.SampleRate;
            frs1=sur1.getFireRate(timebininsec);
            vals=nan(numel(sus),size(frs1.getValues,2));
            for isu=1:numel(sus)
                su=sus(isu);
                sur=neuro.spike.SpikeUnitRaw(su.Id,su.Times);
                sur.Info=su.Info;
                sur.NumberOfSamples=su.NumberOfSamples;
                sur.SampleRate=su.SampleRate;
                frs1=sur.getFireRate(timebininsec);
                try
                    vals(isu,:)=zscore(frs1.getValues,0,2);
                catch
                end
            end
            frs=neuro.spike.FireRatesRaw(vals,[sus.Id]);
            frs.Info.TimebinInSec=timebininsec;
            frs.ClusterInfo=obj.ClusterInfo;
            frs.SampleRate=frs1.SampleRate;
        end        
        function tsz=getFireRatesMeanZScoredRaw(obj,timebininsec)
            sus=obj.getSpikeUnits;
            sumdata=[];
            f = waitbar(0, 'Starting');
            for isu=1:numel(sus)
                su=sus(isu);
                sur=neuro.spike.SpikeUnitRaw(su.Id,su.Times);
                sur.Info=su.Info;
                sur.NumberOfSamples=su.NumberOfSamples;
                sur.SampleRate=su.SampleRate;
                frs1=sur.getFireRate(timebininsec);
                
                if isempty(sumdata)
                    sumdata=zscore(frs1.getValues,0,2);
                else
                    sumdata=sumdata+zscore(frs1.getValues,0,2);
                end
                waitbar(isu/numel(sus), f, sprintf('Progress: %d %%', ...
                    floor(isu/numel(sus)*100)));
                pause(0.1);
            end
            close(f);
            meanData=sumdata/numel(sus);
            tsz=neuro.basic.TimeSeriesZScored(meanData,frs1.SampleRate);
        end
        function obj=getTimeInterval(obj,timeWindow)
            tbl=obj.SpikeTableInSamples;
            idx=false([height(tbl) 1]);
            for i=1:size(timeWindow,1)
                if isdatetime(timeWindow)
                    s=obj.TimeIntervalCombined.getSampleForClosest(timeWindow);
                elseif isduration(timeWindow)
                    s=obj.TimeIntervalCombined.getSampleForClosest( ...
                        obj.TimeIntervalCombined.getDate+timeWindow);
                elseif strcmpi(class(timeWindow),'time.ZeitgeberTime')
                    s=obj.TimeIntervalCombined.getSampleForClosest( ...
                        timeWindow.getAbsoluteTime);
                end
                idx=idx|(tbl.SpikeTimes>=s(i,1))&(tbl.SpikeTimes<s(i,2));
            end
            tbl(~idx,:)=[];
            tbl.SpikeTimes=tbl.SpikeTimes-s(1,1);
            obj.SpikeTableInSamples=tbl;
            obj.Info.TimeFrame=timeWindow;
            obj.TimeIntervalCombined=...
                obj.TimeIntervalCombined.getTimeIntervalForSamples(...
                s);
        end
        function spikeUnits=getSpikeUnits(obj,idx)
            tbl=obj.SpikeTableInSamples;
            ci=obj.ClusterInfo;
            if exist('idx','var') && ~isempty(idx)
                ci_sub=ci(idx,:);
            else
                ci_sub=ci;
            end
            for isid=1:height(ci_sub)
                aci=ci_sub(isid,:);
                spktimes=tbl.SpikeTimes(tbl.SpikeCluster==aci.id);
                su=neuro.spike.SpikeUnit(aci.id,spktimes, ...
                    obj.TimeIntervalCombined);
                su=su.setInfo(aci);
                spikeUnits(isid)=su;
            end
        end
        function obj=keepUnits(obj,idx)
            tbl=obj.SpikeTableInSamples;
            ci=obj.ClusterInfo;
            tbl2=tbl(ismember(tbl.SpikeCluster,ci.id(idx)'),:);
            obj.SpikeTableInSamples=tbl2;
            obj.ClusterInfo=ci(idx,:);
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
                            selected_arg=selected_arg|ismember( ...
                                cluinf.(interest),arg);
                        end
                    end
                end
                selected=selected&selected_arg;
            end
            tbl=obj.SpikeTableInSamples;
            obj.ClusterInfo=obj.ClusterInfo(selected,:);
            obj.SpikeTableInSamples=tbl(ismember(tbl.SpikeCluster,obj.ClusterInfo.id),:);
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
        function [ret]=plus(obj,spikeArrayOrPosition)
            if isa(spikeArrayOrPosition,'neuro.spike.SpikeArray')
            shift=max(obj.ClusterInfo.id);
            sa=spikeArrayOrPosition;
            sa.ClusterInfo.id=sa.ClusterInfo.id+shift;
            sa.SpikeTable.SpikeCluster=sa.SpikeTable.SpikeCluster+shift;
            sa.ClusterInfo=sortrows([obj.ClusterInfo; sa.ClusterInfo], ...
                {'group','sh','ch'});
            sa.SpikeTable=sortrows([obj.SpikeTableInSamples; sa.SpikeTable], ...
                {'SpikeTimes'});
            ret=sa;
            elseif isa(spikeArrayOrPosition,'position.PositionData')||...
                    isa(spikeArrayOrPosition,'position.PositionData1D')||...
                    isa(spikeArrayOrPosition,'position.PositionDataManifold')||...
                    isa(spikeArrayOrPosition,'position.PositionDataTimeLoaded')
                ret=neuro.spike.SpikeArrayTrack(obj,spikeArrayOrPosition);
            end
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
            st=obj.SpikeTableInSamples.SpikeTimes;
        end
        function st=getSpikeTimesZT(obj)
            ts=obj.getSpikeArrayWithAdjustedTimestamps;
            st1=seconds(double(ts.getSpikeTimes)/ ...
                ts.TimeIntervalCombined.getSampleRate); 
            st=obj.TimeIntervalCombined.getStartTimeZT+st1;
        end
        function sc=getSpikeClusters(obj)
            sc=obj.SpikeTableInSamples.SpikeCluster;
        end
    end
end

