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
                    oer=openEphys.OpenEphysRecordRaw(filename);
                    toc
                case '.lfp'
                    fprintf('File loading:\n %s\n',filename)
                    tic
                    oer =openEphys.OpenEphysRecordDownsampled(filename);
                    toc
                otherwise
                    if isfolder(filename)
                        expfols=dir(fullfile(filename,'*experiment*'));
                        for iexp=1:numel(expfols)
                            expfol=expfols(iexp);
                            recfols=dir(fullfile(expfol.folder,expfol.name,'*recording*'));
                            for irec=1:numel(recfols)
                                recfol=recfols(irec);
                                oebin=dir(fullfile(recfol.folder,recfol.name,'*oebin*'));
                                tic
                                try
                                    oer=oer+openEphys.OpenEphysRecordRaw(fullfile(oebin.folder,oebin.name));
                                catch
                                    oer=openEphys.OpenEphysRecordRaw(fullfile(oebin.folder,oebin.name));
                                end
                                toc

                            end
                        end
                    end
                    
            end
%             [path,name,ext]=fileparts(oer.getFile);
%             evtlist=dir(fullfile(path, [name '*.evt']));
%             events=[];
%             for ilist=1:numel(evtlist)
%                 evtfile=evtlist(ilist);
%                 newevents = EventFileFactory.getEvents(...
%                     fullfile(path,evtfile.name));
%                 for ievent=1:numel(newevents)
%                     newevents(ievent).StartDate=...
%                         datestr(oer.getRecordStartTime,...
%                         logistics.TimeFactory.getddmmmyyyyHHMMSSFFF);
%                 end
%                 events=[events newevents];
%             end
%             oer=oer.addEvents(events);
        end
    end
end

