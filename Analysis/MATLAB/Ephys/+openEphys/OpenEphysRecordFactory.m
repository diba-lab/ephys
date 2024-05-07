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
                case '.txt'
                    list=readcell('/data2/gdrive/ephys/AI/2021-08-12_Day7-SD/list.txt','Delimiter','');
                    for ilist=1:numel(list)
                        path=list{ilist};
                        oer1=openEphys.OpenEphysRecordFactory.getOpenEphysRecord(path);
                        try
                            oer=oer+oer1;
                        catch
                            oer=oer1;
                        end
                    end
                otherwise
                    if isfolder(filename)
                        expfols=dir(fullfile(filename,'*experiment*'));
                        if isempty( expfols)
                            allFolders=dir(fullfile(filename));
                            isSubfolder = [allFolders(:).isdir] & ~strcmp({allFolders(:).name}, '.') & ~strcmp({allFolders(:).name}, '..'); % Logical index for subfolders
                            subfolders = {allFolders(isSubfolder).name}; % Extract subfolder names
                            expfols=dir(fullfile(filename,subfolders{1},'*experiment*'));
                        end
                        for iexp=1:numel(expfols)
                            expfol=expfols(iexp);
                            recfols1=dir(fullfile(expfol.folder,expfol.name,'*recording*'));
                            recfols=recfols1([recfols1.isdir]);
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

