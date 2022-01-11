classdef Events
    %EVENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        info
        timetable
    end
    
    methods
        function obj = Events(timetable1,info)
            %EVENT Construct an instance of this class
            %   Detailed explanation goes here
            if exist('timetable1','var')
                obj.timetable = timetable1;
            else
                obj.timetable = [];
            end
            if exist('info','var')
                obj.info = info;
            else
                obj.info = [];
            end
        end
        
        function tt = getTimetable(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            tt= obj.timetable;
        end
        function obj=plus(obj,events)
            ttold=obj.timetable;
            if isa(events,'neuro.event.Events')
                ttnew=events.timetable;
            elseif istimetable(events)
                ttnew=events;
            else
                l=logging.Logger.getLogger;
                l.error('IncorrectType');
            end
            obj.timetable=sortrows([ttold ; ttnew]);
            if isa(events,'neuro.event.Events') && ~isequaln(obj.info,events.info)
                obj.info=[obj.info;events.info];
            end
        end
        function obj=get(obj, varargin)
            if isstring(varargin{1})||ischar(varargin{1})
                var1=varargin{1};
                val1=varargin{2};
            end
            tt1=obj.timetable;
            tt=tt1(ismember(tt1.(var1),val1),:);
            obj.timetable=tt;
        end
end
end

