classdef SDBlocks
    %EXPERIMENTBLOCKTIMES Summary of this class goes here
    %   Detailed explanation goes here
    %     ExperimentBlockTimes(datetime('2019-12-22'),...
    %     {duration(4,1,15),duration(8,0,0)},...
    %     {duration(8,10,40),duration(12,59,53)},...
    %     {duration(13,19,05),duration(14,56,59)},...
    %     {duration(13,19,05),duration(15,00,13)})
    
    properties
        Date
        TimeTable
        ZeitgeberTime
    end
    
    methods
        function obj = SDBlocks(date,T)
            %EXPERIMENTBLOCKTIMES Construct an instance of this class
            %   Detailed explanation goes here
            obj.TimeTable=T;
            obj.TimeTable.Block=categorical(obj.TimeTable.Block);
            obj.Date=date;
        end
        function wind = get(obj,varargin)
            T=obj.TimeTable;
            blocks=categorical(T.Block);
            idx=true(size(blocks));
            if nargin>1
                try
                    idx=ismember(blocks,varargin);
                    if any(ismember(categorical({'SD','NSD'}), varargin))
                        idx=ismember(blocks,categorical({'SD','NSD','SD_NSD'}));
                    end
                catch ME
                    if strcmp(ME.identifier,'MATLAB:categorical:ismember:TypeMismatch')
                        idx=ismember(blocks,varargin{:});
                        if any(ismember(categorical({'SD','NSD'}), varargin{:}))
                            idx=ismember(blocks,categorical({'SD','NSD','SD_NSD'}));
                        end
                    else
                        throw(ME);
                    end
                end

            end
            block=T(idx,:);
            wind=[block.t1 block.t2];
        end
        function T = getTimeTable(obj,varargin)
            T=obj.TimeTable;
            T.t1=T.t1+obj.Date;
            T.t2=T.t2+obj.Date;
        end
        function names = getBlockNames(obj,varargin)
            T=obj.TimeTable;
            names=T.Block;
        end
        function date = getDate(obj)
            date=obj.Date;
        end
        function str = print(obj)
            t=obj.TimeTable;
            date=obj.getDate;
            str=sprintf('%s',datestr(date));
            for ib=1:height(t)
                t1=t(ib,:);
                strs{ib}=sprintf('%s <%s-%s>', t1.Block{1},...
                    datestr(t1.t1,15), datestr(t1.t2,15));
            end
            str=sprintf('\n%s\n\t%s',str,strjoin(strs,';\t'));
        end
        function obj = getZeitgeberTimes(obj)
            t=obj.TimeTable;
            t.t1=t.t1-obj.ZeitgeberTime;
            t.t2=t.t2-obj.ZeitgeberTime;
            obj.TimeTable=t;
        end
        function plot(obj,ax,yShadeRatio)
%             yShadeRatio=[.85 1];
            t=obj.TimeTable;
            if exist('ax','var')
                axes(ax);
            else
                ax=gca;
            end
            hold1=ishold(ax);
            hold(ax,"on");
            if isdatetime(ax.XLim)
                t1=t.t1+obj.Date;
                t2=t.t2+obj.Date;
            else
                t1=hours(t.t1-obj.ZeitgeberTime);
                t2=hours(t.t2-obj.ZeitgeberTime);
            end
            colors=linspecer(height(t));
            for ib=1:height(t)
                tb=t(ib,:);
                y=[ax.YLim(1)+diff(ax.YLim)*yShadeRatio(1) ax.YLim(1)+diff(ax.YLim)*yShadeRatio(2)];
                f1=fill([t1(ib) t2(ib) t2(ib) t1(ib)],[y(1) y(1) y(2) y(2)],colors(ib,:));
                f1.FaceAlpha=.2;f1.LineStyle='none';
                tx1=text(mean([t1(ib) t2(ib)]),mean(y),tb.Block);
                tx1.FontSize=9;tx1.Color=colors(ib,:);tx1.HorizontalAlignment='center';
            end
            if ~hold1, hold(ax,"off");end
        end
    end
end

