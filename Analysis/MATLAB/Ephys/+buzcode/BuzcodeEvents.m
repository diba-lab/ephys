classdef BuzcodeEvents
    %BUZCODEEVENTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EventsFolder
        EventsArray
    end
    
    methods
        function obj = BuzcodeEvents(varargin)
            %BUZCODEEVENTS Construct an instance of this class
            %   Detailed explanation goes here
            if isa(varargin{1},'neuro.event.Events')
                event=varargin{1};
                obj.EventsFolder=event.info.path;
                evts1=event.get('Type','peak').getTableTypesInColumn.Peak;
                evts=[ones(numel(evts1),1) evts1];
                obj.EventsArray=evts;
            elseif isa(varargin{1},'neuro.ripple.RippleAbs')
                event=varargin{1};
                obj.EventsFolder=event.DetectorInfo.BasePath;
                evts1=event.getPeakTimes;
                evts=[ones(numel(evts1),1) evts1];
                obj.EventsArray=evts;
            elseif isa(varargin{1},'time.TimeWindowsDuration')
                event=varargin{1};
                evts1=seconds(mean([event.TimeTable.Start event.TimeTable.Stop],2));
                evts=[ones(numel(evts1),1) evts1];
                obj.EventsArray=evts;
            else
                l=logging.Logger.getLogger;
                l.error('Unknown type.')
            end
        end
        
        function [] = savemat(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            events = obj.EventsArray;
            save(fullfile(obj.EventsFolder,'BuzcodeEventsCouldBeAnyKind'),'events')
        end
        function obj = plus(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isa(varargin{1},'buzcode.BuzcodeEvents')
                buzcodeevent=varargin{1};
                thisarray=obj.EventsArray;
                newbase=max(thisarray(:,1));
                newarr1=buzcodeevent.EventsArray;
                newarr1(:,1)=newarr1(:,1)+newbase;
                obj.EventsArray=[thisarray; newarr1];
            else
                l=logging.Logger.getLogger;
                l.error('Unknown type.')
            end
        end
        
    end
end

