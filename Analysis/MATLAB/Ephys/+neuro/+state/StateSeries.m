classdef StateSeries
    %STATESERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        States
        Episodes
        TimePoints
        TimeIntervalCombined
        StateNames
    end
    
    methods
        function obj = StateSeries(states, ticd)
            obj.TimeIntervalCombined=ticd;
            obj.States=states;
        end
        function obj = getZTCorrected(obj)
            ticd=obj.TimeIntervalCombined;
            ztadj=ticd.getStartTime-ticd.getZeitgeberTime;
            fnames=fieldnames(obj.Episodes);
            for istate=1:numel(fnames)
                thestate=fnames{istate};
                obj.Episodes.(thestate)=hours(seconds(ticd.adjustTimestampsAsIfNotInterrupted( ...
                    obj.Episodes.(thestate)*ticd.getSampleRate)/ticd.getSampleRate) + ztadj);
            end
            obj.TimePoints=hours(seconds(ticd.adjustTimestampsAsIfNotInterrupted( ...
                    obj.TimePoints*ticd.getSampleRate)/ticd.getSampleRate) + ztadj);
        end
        function obj = getWindow(obj,window)
            states=obj.States;
            ticd=obj.TimeIntervalCombined;
            episodes=obj.Episodes;
            
            if ~isdatetime(window)
                winddt=ticd.getDate+window;
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
            idx=winsInSample(1):winsInSample(2);
            winInSec=obj.TimePoints(idx);
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
                epinew=epi(idx,:);
                if ~isempty(epinew)
                    if epinew(1,1)<min(winInSec)
                        epinew(1,1)=min(winInSec);
                    end
                    if epinew(end,2)>max(winInSec)
                        epinew(end,2)=max(winInSec);
                    end
                end
                epinew=epinew-min(winInSec)+1;
                episodes.(fnames{iepi})=epinew;
            end
            obj.States=states_new;
            obj.TimePoints=winInSec-min(winInSec)+1;
            obj.Episodes=episodes;
            obj.TimeIntervalCombined=ticd_new;
        end
        function newobj = getResampled(obj,timeIntervalCombined)
            if isa(timeIntervalCombined,'neuro.basic.Channel')
                timeIntervalCombined=timeIntervalCombined.getTimeIntervalCombined;
            end
            timePointsInSec=seconds(timeIntervalCombined.getTimePoints);
            ts=obj.getTimeSeries;
            ts1=ts.resample(timePointsInSec,'zoh');
            states1=ts1.Data;
            newobj=neuro.state.StateSeries(states1,timeIntervalCombined);
        end
        function [ax] = plot(obj,yShadeRatio)
%             yShadeRatio=[.55 .8];
            ax=gca;
            hold1=ishold(ax);hold(ax,"on");
            y=[ax.YLim(1)+diff(ax.YLim)*yShadeRatio(1) ax.YLim(1)+...
                diff(ax.YLim)*yShadeRatio(2)];
            obj1=obj.getZTCorrected;
            episodes=obj1.Episodes;
            fnames=fieldnames(episodes);
            hold on;
            colors=linspecer(numel(fnames));
            for istate=1:numel(fnames)
                thestate=episodes.(fnames{istate});
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
            if exist('windowZT','var')
                strt1=round( ...
                    hours(hours(windowZT(1)):slidingWindowLaps:(hours(windowZT(2))-slidingWindowSize/2)) ...
                    ,3);
            else
                strt1=round(hours( ...
                    hours(obj1.TimePoints(1)):slidingWindowLaps:hours((obj1.TimePoints(end)/2)) ...
                    ),3);
            end
            end1=strt1+hours(slidingWindowSize);

            center1=array2table( [hours(strt1)' hours(strt1)'+ ...
                slidingWindowSize/2 hours(end1)'], ...
                VariableNames={'ZTStart','ZTCenter','ZTEnd'});
            wind=nan(size(strt1,2),6);
            for iwin=1:numel(strt1)
                s1=strt1(iwin);
                e1=end1(iwin);
                [n,c]=histcounts(states(obj1.TimePoints>s1&obj1.TimePoints<e1));
                statelist={'0','1','2','3','4','5',};
                [b,a]=ismember(statelist,c);
                wind(iwin,b)=n(a(b));
            end
            statecounts=array2table(wind,VariableNames={'none','A-WAKE', ...
                'Q-WAKE','SWS','INT','REM'});
            restbl=[center1 statecounts];
        end
        function [theEpisodeAbs tbls]=getState(obj,states)
            stateEpisodes=obj.getEpisodes;
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
                tbl=array2table(theEpisode,"VariableNames",{'start','end'});
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
                    theEpisodeAbs(irow,:)=ticdss.getStartTime+seconds(wind);
                end
            else
                theEpisodeAbs=[];
            end
        end
        function obj=setEpisodes(obj,episodes)
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

