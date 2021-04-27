classdef OpenEphysRecordFactory
    %OPENEPHYSRECORDFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
    end
    methods (Static)
        function oer = getOpenEphysRecord(filename)
            [~,~,ext]=fileparts(filename);
            switch ext
                case {'.oebin','.openephys'}
                    fprintf('File loading:\n %s\n',filename)
                    tic
                    oer=OpenEphysRecordRaw(filename);
                    toc
                case '.lfp'
                    fprintf('File loading:\n %s\n',filename)
                    tic
                    oer = OpenEphysRecordDownsampled(filename);
                    toc
                otherwise
                    
            end
            [path,name,ext]=fileparts(oer.getFile);
            evtlist=dir(fullfile(path, [name '*.evt']));
            events=[];
            for ilist=1:numel(evtlist)
                evtfile=evtlist(ilist);
                newevents = EventFileFactory.getEvents(...
                    fullfile(path,evtfile.name));
                for ievent=1:numel(newevents)
                    newevents(ievent).StartDate=...
                        datestr(oer.getRecordStartTime,...
                        TimeFactory.getddmmmyyyyHHMMSSFFF);
                end
                events=[events newevents];
            end
            oer=oer.addEvents(events);
        end
    end
end

