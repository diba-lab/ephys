classdef (Abstract) SDLoader < Singleton
    %SDLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = protected)
        activeOpenEphysRecord
        activeWorkspaceFile
        datafolder
        eventData
        videos
        tracks
        probe
    end
    methods(Access = private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
    end
    methods
        function folder=getActiveWorkspaceFolder(obj)
            folder=obj.activeWorkspaceFile;
        end
        function oerc = getActiveOpenEphysRecord(obj)
            if ~isempty(obj.activeOpenEphysRecord)
                oerc=obj.activeOpenEphysRecord ;
            else
                error('No Active OpenEphysRecord Loaded before.')
            end
        end
        function [oer,obj]= getNewOpenEphysRecord(obj,oebin_file)
            obj.activeOpenEphysRecord = OpenEphysRecord(oebin_file);
            oer=obj.activeOpenEphysRecord ;
        end
        function [oer,obj] = getNewOpenEphysRecordUI(obj)
            cf=cd(obj.datafolder);
            [file,path] = uigetfile({'*.oebin;*.openephys;*.lfp',...
                'OpenEphys Files (*.oebin,*.openephys,*.lf)'},...
                'Select an oebin File');
            cd(cf);
            obj.activeOpenEphysRecord = ...
                OpenEphysRecord(fullfile(path,file));
            oer=obj.activeOpenEphysRecord ;
        end
        function workspace=getActiveWorkspaceFile(obj)
            workspace=obj.activeWorkspaceFile;
        end
        function obj=loadOERFiles(obj,files)
            for ifile=1:numel(files)
                filename=fullfile(files{ifile});
                oer =OpenEphysRecordFactory.getOpenEphysRecord(filename);
                if ~exist('oerc','var')
                    oerc=oer;
                else
                    oerc=oerc+oer;
                end
            end
            list=dir([obj.activeWorkspaceFile filesep '*Probe*.mat'] );
            try
                prb=Probe(fullfile(list.folder, list.name));
                oerc=oerc.setProbe(prb);
                fprintf('Probe file found for OpenEphysCombined.\n')
            catch
                warning('Probe file could not be found for OpenEphysCombined.\n')
            end 
            obj.activeOpenEphysRecord=oerc;
            
        end
        function obj=loadVideoFiles(obj,files)
            for ifile=1:numel(files)
                filename=fullfile(files{ifile});
                v=VideoFile(filename);
                if ~exist('videoscombined','var')
                    videoscombined=v;
                else
                    videoscombined=videoscombined+v;
                end
            end
            obj.videos=videoscombined;
        end
        function obj=loadTrackFiles(obj,files)
            ol=OptiLoader.instance(files);
            ofs=ol.getFiles;
            for iof=1:numel(ofs)
                of=ofs{iof};
                if ~exist('trackscombined','var')
                    trackscombined=of;
                else
                    trackscombined=trackscombined+of;
                end
            end
            obj.tracks=trackscombined;
        end
        function obj=loadEventFiles(obj,files)
            for ifile=1:numel(files)
                filename=fullfile(files{ifile});
                el=EventLoader.instance;
                evts=el.loadFile(filename);
                obj.eventData=[obj.eventData evts];
                if ~isempty(obj.activeOpenEphysRecord)
                    obj.activeOpenEphysRecord=...
                        obj.activeOpenEphysRecord.addEvents(obj.eventData);
                end
            end
        end
        function vids=getVideos(obj)
            vids=obj.videos;
        end
        function evts=getEvents(obj)
            evts=obj.eventData;
        end
        function evts=getTracks(obj)
            evts=obj.tracks;
        end
        function []=plotTimeline(obj)
            tlc{1}=obj.tracks.getTimeline;
            tlc{2}=obj.videos.getTimeline;
            tlc{3}=obj.activeOpenEphysRecord.getTimeline;
            labels={'Track','Video','Record'};
            color=linspecer(numel(tlc));
            figure('Units','normalized','Position',[.1 .4 .8 .1]);
            for itlc=1:numel(tlc)
                tls=tlc{itlc};
                subplot(numel(tlc),1,itlc);hold on;
                for itls=1:numel(tls)
                    tl=tls{itls};
                    plot(tl.TimeInfo.StartDate,double(tl.Data(1)));
                    p1=tl.plot;
                    xtickformat('h:mm:ss');
                    p1(1).Color=color(itlc,:);
                    p1(1).LineStyle='none';
                    p1(1).Marker='.';
                    p1(1).MarkerSize=10;
                    try
                        p1(2).Marker='v';
                        p1(2).MarkerFaceColor='none';
                    catch
                        
                    end
                end
                ax=gca;
                ax.Position=[ax.Position(1) ax.Position(2)...
                    ax.Position(3) ax.Position(4)*.25];
                d=ax.XLim(1);
                d.Format = 'dd-MMM-yyyy';
                c1 = cellstr(d);         % Cell array of strings.
                d.Format = 'hh:mm:ss';
                c2 = {'04:00:00'};
                c3 = {'20:00:00'};
                ax.XLim=[datetime([c1{:} ' ' c2{:}])...
                    datetime([c1{:} ' ' c3{:}])];
                ax.Color='none';
                ax.Box='off';
                ax.YTickLabel='';
                text(-.05,.5,labels{itlc},'Units','normalized');
                if itlc~=numel(tlc)
                    ax.Visible='off';
                    ax.XTickLabel='';
                end
            end
        end
    end
end

