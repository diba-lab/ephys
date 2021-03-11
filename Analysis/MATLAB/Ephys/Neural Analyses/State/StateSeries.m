classdef StateSeries
    %STATESERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        States
        Episodes
        TimeIntervalCombined
        StateNames
    end
    
    methods
        function obj = StateSeries(states, ticd)
            obj.TimeIntervalCombined=ticd;
            obj.States=states(1:ticd.getNumberOfPoints);
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
            winsInsec=ticd.getSampleFor(winddt)/ticd.getSampleRate;
            if isnan(winsInsec(1))
                try
                    til=ticd.timeIntervalList;
                    %get closest start time
                    for il=1:til.length
                        ti=til.get(il);
                        sttimes(il)=ti.getStartTime; %#ok<AGROW>
                    end
                    [~,idx]=min(abs(sttimes-window(1)));
                    winddt(1)=sttimes(idx);
                catch
                    winddt(1)=ticd.getStartTime;
                end
            end
            if isnan(winsInsec(2))
                try
                    til=ticd.timeIntervalList;
                    %get closest end time
                    for il=1:til.length
                        ti=til.get(il);
                        endtimes(il)=ti.getEndTime; %#ok<AGROW>
                    end
                    [~,idx]=min(abs(endtimes-window(2)));
                    winddt(2)=endtimes(idx);
                catch
                    winddt(2)=ticd.getEndTime;
                end
            end
            winsInsec=ticd.getSampleFor(winddt)/ticd.getSampleRate;

            idx=winsInsec(1):winsInsec(2);
            states_new=states(idx);
            ticd_new=ticd.getTimeIntervalForTimes(winddt);
            fnames=fieldnames(  episodes);
            for iepi=1:numel(fnames)
                epi=episodes.(fnames{iepi});
                start=epi(:,1);
                stop=epi(:,2);
                idxstart=start>winsInsec(1)&start<winsInsec(2);
                idxstop=stop>winsInsec(1)&stop<winsInsec(2);
                idx=idxstart|idxstop;
                epinew=epi(idx,:);
                if ~isempty(epinew)
                    if epinew(1,1)<winsInsec(1)
                        epinew(1,1)=winsInsec(1);
                    end
                    if epinew(end,2)>winsInsec(2)
                        epinew(end,2)=winsInsec(2);
                    end
                end
                epinew=epinew-winsInsec(1)+1;
                episodes.(fnames{iepi})=epinew;
            end
            obj.States=states_new;
            obj.Episodes=episodes;
            obj.TimeIntervalCombined=ticd_new;
        end
        function newobj = getResampled(obj,timeIntervalCombined)
            if isa(timeIntervalCombined,'Channel')
                timeIntervalCombined=timeIntervalCombined.getTimeIntervalCombined;
            end
            timePointsInSec=timeIntervalCombined.getTimePointsInSec;
            ts=obj.getTimeSeries;
            ts1=ts.resample(timePointsInSec,'zoh');
            states1=ts1.Data;
            newobj=StateSeries(states1,timeIntervalCombined);
        end
        function [] = plot(obj,colorMap)
            states1=obj.States;
            ticd=obj.TimeIntervalCombined;
            t=seconds(ticd.getTimePointsInSec)+ticd.getStartTime;
            hold on;
            num=1;
            if ~exist('colorMap','var')
                sde=SDExperiment.instance;
                colorMap=sde.getStateColors;
            end
            for ikey=colorMap.keys
                statesarr=states1;
                state=ikey{1};
                statesarr(states1~=state)=nan;
                statesarr(states1==state)=num;num=num+1;
                p1=plot(t,statesarr);
                try
                    p1.Color=colorMap(state);
                catch
                    p1.Color=sde.getStateColors(state);
                end
                p1.LineWidth=5;
                
            end
            
                
            ax=gca;
            ax.XLim=[t(1) t(end)];
            ax.YLim=[0 num-1];
            ax.Color='none';
%             ax.Visible='off';
            ax.YDir='reverse';
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
        function state=getStateRatios(obj,slidingWindowSizeInSeconds,slidingWindowLapsInSeconds,edges)
            states=obj.States;
            if isduration( slidingWindowSizeInSeconds)
                slidingWindowSizeInSeconds=seconds(slidingWindowSizeInSeconds);
            end
            if isduration( slidingWindowLapsInSeconds)
                slidingWindowLapsInSeconds=seconds(slidingWindowLapsInSeconds);
            end
            t=obj.TimeIntervalCombined.getTimePointsInSec;
            statesunique=unique(states);
            for istate=1:numel(statesunique)
                thestate=statesunique(istate);
                if sum(ismember(1:5,thestate))
                    idx=states==thestate;
                    tsforthestate=t(idx);
                    [state(thestate).N,state(thestate).edges] =histcounts(tsforthestate,edges);
                    state(thestate).Ratios=state(thestate).N/slidingWindowSizeInSeconds;
                    state(thestate).state=thestate;
                end
            end
            state=StateRatios(state);
        end
        function theEpisodeAbs=getState(obj,state)
            stateEpisodes=obj.getEpisodes;
            stateNames=obj.getStateNames;
            theStateName=stateNames{state};
            theEpisode=stateEpisodes.(strcat(theStateName,'state'));
            ticdss=obj.TimeIntervalCombined;
            theEpisodeAbs=ticdss.getRealTimeFor(theEpisode);
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
            np=timeseries(obj.States,obj.TimeIntervalCombined.getTimePointsInSec);
        end
        function st=getStartTime(obj)
            st=obj.TimeIntervalCombined.getStartTime;
        end
    end
end

