classdef StateSeries
    %STATESERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        States % # of time points == ticd.getNumerOfPoints
        Episodes % Starts at 0 seconds equals to ticd.getStartTime
        TimeIntervalCombined % First data point is at ticd.getStartTime
        StateNames % Each coresponds to the numbers in States here
    end
    
    methods
        function obj = StateSeries(states, ticd)
            obj.TimeIntervalCombined=ticd;
            obj.States=states;
            if ticd.getNumberOfPoints~=numel(states)
                error(['\n\t # in TimeInterval (%d) and data (%d) ' ...
                    'are not equal.'],ticd.getNumberOfPoints,numel(states))
            end
        end
        function dur = getDuration(obj)
            dur=obj.TimeIntervalCombined.getDuration;
        end
        function obj = getZTCorrected(obj)
            ticd=obj.TimeIntervalCombined;
            ztadj=ticd.getStartTime-ticd.getZeitgeberTime;
            fnames=fieldnames(obj.Episodes);
            for istate=1:numel(fnames)
                thestate=fnames{istate};
                timeCorrected=seconds( ...
                    ticd.adjustTimestampsAsIfNotInterrupted( ...
                    seconds(obj.Episodes.(thestate))* ...
                    ticd.getSampleRate)/ticd.getSampleRate);
                obj.Episodes.(thestate)=timeCorrected + ztadj;
            end
        end
        function obj = getWindow(obj,window)
            states=obj.States;
            ticd=obj.TimeIntervalCombined;
            episodes=obj.Episodes;
            
            if isduration(window)
                winddt=ticd.getDate+window;
            elseif isa(window,'time.ZT')
                winddt=ticd.getZeitgeberTime+window.Duration;
            else
                winddt=window;
            end
            winsInSample=ticd.getSampleFor(winddt);
            if isnan(winsInSample(1))
                try
                    til=ticd.timeIntervalList;
                    %get closest start time
                    for il=1:til.length
                        ti=til.get(il);
                        sttimes(il)=ti.getStartTime; %#ok<AGROW>
                    end
                    [~,idx]=min(abs(sttimes-winddt(1)));
                    winddt(1)=sttimes(idx);
                catch
                    winddt(1)=ticd.getStartTime;
                end
            end
            if isnan(winsInSample(2))
                try
                    til=ticd.timeIntervalList;
                    %get closest end time
                    for il=1:til.length
                        ti=til.get(il);
                        endtimes(il)=ti.getEndTime; %#ok<AGROW>
                    end
                    [~,idx]=min(abs(endtimes-winddt(2)));
                    winddt(2)=endtimes(idx);
                catch
                    winddt(2)=ticd.getEndTime;
                end
            end
            winsInSample=ticd.getSampleFor(winddt);
            winInSec=seconds((winsInSample-1)*ticd.getSampleRate);
            idx=winsInSample(1):winsInSample(2);
            states_new=states(idx);
            ticd_new=ticd.getTimeIntervalForTimes(winddt);
            fnames=fieldnames(episodes);
            for iepi=1:numel(fnames)
                epi=episodes.(fnames{iepi});
                start=epi(:,1);
                stop=epi(:,2);
                idxstart=start>min(winInSec)&start<max(winInSec);
                idxstop=stop>min(winInSec)&stop<max(winInSec);
                idx=idxstart|idxstop;
                try
                    epinew=epi(idx,:);
                catch ME
                    
                end
                if ~isempty(epinew)
                    if epinew(1,1)<min(winInSec)
                        epinew(1,1)=min(winInSec);
                    end
                    if epinew(end,2)>max(winInSec)
                        epinew(end,2)=max(winInSec);
                    end
                end
                epinew=epinew-min(winInSec);
                episodes.(fnames{iepi})=epinew;
            end
            obj.States=states_new;
            obj.Episodes=episodes;
            obj.TimeIntervalCombined=ticd_new;
        end
        function newobj = getResampled(obj,timeIntervalCombined)
            if isa(timeIntervalCombined,'neuro.basic.Channel')
                timeIntervalCombined=...
                    timeIntervalCombined.getTimeIntervalCombined;
            end
            timePointsInSec=seconds(timeIntervalCombined.getTimePoints);
            ts=obj.getTimeSeries;
            ts1=ts.resample(timePointsInSec,'zoh');
            states1=ts1.Data;
            newobj=neuro.state.StateSeries(states1,timeIntervalCombined);
        end
        function [ax] = plot(obj,yShadeRatio)
%             yShadeRatio=[.55 .8];
            statesOrder=categorical({'NREMstate','REMstate', ...
                'WAKEstate','QWAKEstate'});
            ax=gca;
            hold1=ishold(ax);hold(ax,"on");
            y=[ax.YLim(1)+diff(ax.YLim)*yShadeRatio(1) ax.YLim(1)+...
                diff(ax.YLim)*yShadeRatio(2)];
            episodes=obj.Episodes;
            fnames=categorical(sort(fieldnames(episodes)));
            [~,loc]=ismember(fnames,statesOrder);
            fnames=fnames(loc);
            hold on;
            colors=linspecer(numel(fnames));
            for istate=1:numel(fnames)
                thestate=hours(episodes.(string(fnames(istate))));
                for iepisode=1:size(thestate,1)
                    episode=thestate(iepisode,:);
                    fl=fill([episode(1) episode(2) episode(2) episode(1)], ...
                        [y(1) y(1) y(2) y(2)],colors(istate,:));
                    fl.LineStyle='none';
                    fl.FaceAlpha=.5;
                end
            end   
            ax.Color='none';
            if ~hold1,hold(ax,"off");end
        end
        function np=getNumberOfPoints(obj)
            np=numel(obj.States);
        end
        function idx=getIndexForWindow(obj,window)
            t1=obj.TimeIntervalCombined.getSampleFor(window(1));
            t2=obj.TimeIntervalCombined.getSampleFor(window(2));
            idx=zeros(1,obj.TimeIntervalCombined.getNumberOfPoints);
            idx(1,t1:t2)=1;
        end
        function idx=getIndexForState(obj,state)
            idx=obj.States==state;
            idx=idx';
        end
        function restbl=getStateRatios(obj,slidingWindowSize, ...
                slidingWindowLaps,windowZT)
            obj1=obj.getZTCorrected;
            states=categorical(obj1.States);
            if nargin<2
                slidingWindowSize=obj.TimeIntervalCombined.getDuration;
                slidingWindowLaps=slidingWindowSize;
            end
            if exist('windowZT','var')
                strt1=hours(windowZT(1):slidingWindowLaps: ...
                    (windowZT(2)-slidingWindowSize+slidingWindowLaps));
            else
                zt=obj.TimeIntervalCombined.getZeitgeberTime;
                strt1=hours((obj1.getStartTime-zt):...
                    slidingWindowLaps: ...
                    (obj1.getEndTime-zt-slidingWindowSize+ ...
                    slidingWindowSize/100) ) ;
            end
            if isempty(strt1)
                strt1=hours(obj1.getStartTime-zt);
            end
            if nargin>1
                roundAccuracy=hours(1)/slidingWindowLaps;
                strt2=round(roundAccuracy*strt1)/roundAccuracy;
            else
                strt2=strt1;
            end

            end2=strt2+hours(slidingWindowSize);
            center1=array2table( hours([strt2' strt2'+ ...
                hours(slidingWindowSize)/2 end2']), ...
                VariableNames={'ZTStart','ZTCenter','ZTEnd'});
            wind=zeros(size(strt2,2),6);
            timePoints=hours(obj.TimeIntervalCombined.getTimePointsZT);
            for iwin=1:numel(strt2)
                s1=strt2(iwin);
                e1=end2(iwin);
                [n,c]=histcounts(states(timePoints>=s1&timePoints<=e1));
                statelist={'0','1','2','3','4','5',};
                [b,a]=ismember(statelist,c);
                wind(iwin,b)=n(a(b));
            end
            statecounts=array2table(seconds(wind),VariableNames={ ...
                'none','A-WAKE','Q-WAKE','SWS','INT','REM'});
            restbl=neuro.state.StateRatios([center1 statecounts]);
        end
        function [theEpisodeAbs, tbls]=getState(obj,states)
            ticd=obj.TimeIntervalCombined;
            stateEpisodes=obj.getEpisodes;
            if ~iscategorical(states)
                if iscell(states)
                    states=categorical(states);
                else
                    states=categorical({states});
                end
            end
            tbls=[];
            for is=1:numel(states)
                state=states(is);
                if state=="AWAKE"
                    theEpisode=stateEpisodes.(strcat('WAKE','state'));
                elseif state=="SWS"
                    theEpisode=stateEpisodes.(strcat('NREM','state'));
                else
                    theEpisode=stateEpisodes.(strcat(string(state),'state'));
                end
                theEpisode=ticd.adjustTimestampsAsIfNotInterrupted( ...
                    seconds(theEpisode)*ticd.getSampleRate)/ticd.getSampleRate;
                tbl=array2table(seconds(theEpisode),"VariableNames",{ ...
                    'start','end'});
                tbl=[tbl array2table(repmat(state,[height(tbl),1]), ...
                    "VariableNames",{'state'})];
                if is==1
                    tbls=tbl;
                else
                    tbls=[tbls;tbl];
                end
            end
            tbls=sortrows(tbls,'start');
            if ~isempty(tbls)
                ticdss=obj.TimeIntervalCombined;
                for irow=1:height(tbls)
                    wind=[tbls(irow,:).start tbls(irow,:).end];
                    theEpisodeAbs(irow,:)=ticdss.getStartTime+wind;
                end
                tbls=[tbls array2table(theEpisodeAbs,VariableNames={ ...
                    'AbsStart','AbsEnd'})];
            else
                theEpisodeAbs=[];
            end
        end
        function obj=setEpisodesFromBuzcode(obj,episodes)
            fnames=fieldnames(episodes);
            for ifnames=1:numel(fnames)
                state=episodes.(fnames{ifnames});
                tmp=seconds(state-1); % now zero is the start time at ticd
                tmp(:,1)=tmp(:,1)-seconds(.5);
                tmp(:,2)=tmp(:,2)+seconds(.5);
                episodes.(fnames{ifnames})=tmp;
            end
            obj.Episodes=episodes;
        end
        function epi=getEpisodes(obj)
            epi=obj.Episodes;
        end
        function obj=setStateNames(obj,names)
            obj.StateNames=names;
        end
        function name=getStateNames(obj)
            name=obj.StateNames;
        end
        function np=getTimeSeries(obj)
            np=timeseries(obj.States,obj.TimeIntervalCombined.getTimePoints);
        end
        function st=getStartTime(obj)
            st=obj.TimeIntervalCombined.getStartTime;
        end
        function st=getEndTime(obj)
            st=obj.TimeIntervalCombined.getEndTime;
        end
    end
end

