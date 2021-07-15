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
    end
    
    methods
        function obj = SDBlocks(date,T)
            %EXPERIMENTBLOCKTIMES Construct an instance of this class
            %   Detailed explanation goes here

            obj.TimeTable=T;
            obj.Date=date;
        end
        function wind = get(obj,varargin)
            T=obj.TimeTable;
            blocks=T.Block;
            idx=true(size(blocks));
            if nargin>1
                idx=ismember(blocks,varargin);
                if any(ismember({'SD','NSD'}, varargin))
                    idx=ismember(blocks,{'SD','NSD','SD_NSD'});
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
    end
end

