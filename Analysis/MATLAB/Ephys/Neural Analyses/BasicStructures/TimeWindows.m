classdef TimeWindows
    %TIMEWINDOWS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimeTable
        TimeIntervalCombined
    end
    
    methods
        function obj = TimeWindows(timeTable,ticd)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least 
            % two datetime value columns: Start, Stop
            if isstruct(timeTable)
                timeTable=struct2table(timeTable);
            end
            obj.TimeTable = timeTable;
            if exist('ticd','var'), obj.TimeIntervalCombined=ticd; end
        end
        function this = SetTimeIntervalCombined(this,ticd)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least 
            % two datetime value columns: Start, Stop
            this.TimeIntervalCombined=ticd;
        end
        
        function timeWindows = plus(thisTimeWindows,newTimeWindows)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t1=thisTimeWindows.TimeTable;
            t2=newTimeWindows.TimeTable;
            tRes=t1;
            tRes(:,:)=[];
            art_count=0;
            for iwin=1:height(t1)
                art_base=t1(iwin,:);
                base.start=art_base.Start;
                base.stop=art_base.Stop;
                
                new_start_is_in_old_ripple=(t2.Start>base.start & t2.Start<base.stop);
                new_stop_is_in_old_ripple=(t2.Stop>base.start & t2.Stop<base.stop);
                idx=new_start_is_in_old_ripple|new_stop_is_in_old_ripple;
                if sum(idx)>1 
                    x=find(idx);
                    idx1=false(size(idx));
                    idx1(x(1))=true; 
                    idx=idx1;
                end
                rippleHasNoOverlap=~sum(idx);
                if rippleHasNoOverlap
                    art_count=art_count+1;
                    tRes(art_count,:)=art_base;
                else
                    art_count=art_count+1;
                    art_new=t2(idx,:);t2(idx,:)=[];
                    if art_new.Start<art_base.Start, art_base.Start=art_new.Start;end
                    if art_new.Stop>art_base.Stop, art_base.Stop=art_new.Stop;end
                    tRes(art_count,:)=art_base;
                end
            end
            tRes=[tRes;t2];
            tRes=sortrows(tRes, 'Start');
            timeWindows=TimeWindows(tRes,thisTimeWindows.TimeIntervalCombined);
        end
        function ax=plot(obj,ax)
            T=obj.TimeTable;
            start=T.Start;
            stop=T.Stop;
            if ~exist('ax','var'), ax=gca;end
            hold on;
            for iart=1:numel(start)
                x=[start(iart) stop(iart)];
                y=[ax.YLim(2) ax.YLim(2)];
                p=area(ax,x,y);
                p.BaseValue=ax.YLim(1);
                p.FaceAlpha=.5;
                p.FaceColor='r';
                p.EdgeColor='none';
            end
        end
        function ax=saveForClusteringSpyKingCircus(obj,ax)
            T=obj.TimeTable;
            start=T.Start;
            stop=T.Stop;
            if ~exist('ax','var'), ax=gca;end
            hold on;
            for iart=1:numel(start)
                x=[start(iart) stop(iart)];
                y=[ax.YLim(2) ax.YLim(2)];
                p=area(ax,x,y);
                p.BaseValue=ax.YLim(1);
                p.FaceAlpha=.5;
                p.FaceColor='r';
                p.EdgeColor='none';
            end
        end
        function ax=saveForNeuroscope(obj,ax)
            T=obj.TimeTable;
            start=T.Start;
            stop=T.Stop;
            if ~exist('ax','var'), ax=gca;end
            hold on;
            for iart=1:numel(start)
                x=[start(iart) stop(iart)];
                y=[ax.YLim(2) ax.YLim(2)];
                p=area(ax,x,y);
                p.BaseValue=ax.YLim(1);
                p.FaceAlpha=.5;
                p.FaceColor='r';
                p.EdgeColor='none';
            end
        end
        function ax=getArrayForBuzcode(obj,ax)
            T=obj.TimeTable;
            start=T.Start;
            stop=T.Stop;
            if ~exist('ax','var'), ax=gca;end
            hold on;
            for iart=1:numel(start)
                x=[start(iart) stop(iart)];
                y=[ax.YLim(2) ax.YLim(2)];
                p=area(ax,x,y);
                p.BaseValue=ax.YLim(1);
                p.FaceAlpha=.5;
                p.FaceColor='r';
                p.EdgeColor='none';
            end
        end
    end
end

