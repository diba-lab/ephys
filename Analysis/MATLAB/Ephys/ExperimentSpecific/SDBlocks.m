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
            end
            wind=T(idx,:);
        end
        function T = getTimeTable(obj,varargin)
            T=obj.TimeTable;
            T.t1=T.t1+obj.Date;
            T.t2=T.t2+obj.Date;
        end
    end
end

