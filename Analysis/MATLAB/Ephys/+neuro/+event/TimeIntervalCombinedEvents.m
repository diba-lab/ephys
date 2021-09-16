classdef TimeIntervalCombinedEvents < neuro.event.Events
    %TIMEINTERVALCOMBINEDEVENTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        timeIntervalCombined
    end
    
    methods
        function obj = TimeIntervalCombinedEvents(events,ticd)
            %TIMEINTERVALCOMBINEDEVENTS Construct an instance of this class
            %   Detailed explanation goes here
            obj.timeIntervalCombined = ticd;
            obj.timetable=events.timetable;
            obj.info=events.info;
        end
        
        function outputArg = saveNeuroscopeEventFiles(obj,folder,variableName)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~exist('folder', 'var')||isempty(folder)
                folder=pwd;
            end
            ticd=obj.timeIntervalCombined;
            tt=obj.timetable;
            vars=unique(tt.(variableName));
            for ivar=1:numel(vars)
                var=vars(ivar);
                filename=variableName;
                subEvents=obj.get(variableName,var);
                subeventstt=subEvents.timetable;
                t=subeventstt.Time;
                smp=neuro.time.Sample(ticd.getSampleFor(t),ticd.getSampleRate);
                ms=seconds(smp.getDuration)*1000;
                fid = fopen(sprintf('%s%s%s.R%02d.evt',folder,filesep,filename,var),'w');
                
                l=logging.Logger.getLogger;
                l.fine('Writing event file ...\n');
                evt=subeventstt.("On-Off");
                for ievent= 1:height(subeventstt)
                    if evt(ievent)
                        fprintf(fid,'%9.1f\t%s\n',ms(ievent),'on');
                    else
                        fprintf(fid,'%9.1f\t%s\n',ms(ievent),'off');
                    end
                end
                fclose(fid);
            end
        end
    end
end

