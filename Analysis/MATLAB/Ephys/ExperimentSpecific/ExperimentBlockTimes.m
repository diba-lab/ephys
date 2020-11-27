classdef ExperimentBlockTimes
    %EXPERIMENTBLOCKTIMES Summary of this class goes here
    %   Detailed explanation goes here
    %     ExperimentBlockTimes(datetime('2019-12-22'),...
    %     {duration(4,1,15),duration(8,0,0)},...
    %     {duration(8,10,40),duration(12,59,53)},...
    %     {duration(13,19,05),duration(14,56,59)},...
    %     {duration(13,19,05),duration(15,00,13)})
    
    properties
        TimeTable
    end
    
    methods
        function obj = ExperimentBlockTimes(date,varargin)
            %EXPERIMENTBLOCKTIMES Construct an instance of this class
            %   Detailed explanation goes here
            
            for iblock=1:numel(varargin)
                duration=varargin{iblock};
                start(iblock,1)=date+duration{1};
                end1(iblock,1)=date+duration{2};
            end
            name={'PRE';'SD';'TRACK';'POST'};
            obj.TimeTable = timetable(start,end1,name);
        end
        function wind = getPRE(obj)
            tt=obj.TimeTable;
            str='PRE';
            wind=[tt.start(strcmpi(tt.name,str)) tt.end1(strcmpi(tt.name,str))];
        end
        function wind = getSD(obj)
            tt=obj.TimeTable;
            str='SD';
            wind=[tt.start(strcmpi(tt.name,str)) tt.end1(strcmpi(tt.name,str))];
        end
        function wind = getTRACK(obj)
            tt=obj.TimeTable;
            str='TRACK';
            wind=[tt.start(strcmpi(tt.name,str)) tt.end1(strcmpi(tt.name,str))];
        end
        function wind = getPOST(obj)
            tt=obj.TimeTable;
            str='POST';
            wind=[tt.start(strcmpi(tt.name,str)) tt.end1(strcmpi(tt.name,str))];
        end
    end
end

