classdef SDDay
    %SDDAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Name
        WorkspaceFolder
        OpenEphysRecordCombined
        OptiFileCombined
        VideoFilesCombined
        EventData
        TimeTableForSessions
        StateDetectionDataCombined
        
    end
    
    methods
        function obj = SDDay(dayName,workspaceFolder)
            obj.Name=dayName;
            obj.WorkspaceFolder=workspaceFolder;
            
        end
        function obj = setOpenEphysRecordCombined(obj,oerc)
            obj.OpenEphysRecordCombined=oerc;
        end
        function obj = setOptiFileCombined(obj,ofc)
            obj.OptiFileCombined=ofc;
        end
        function obj = setVideoFilesCombined(obj,vfc)
            obj.VideoFilesCombined=vfc;
        end
        function obj = setEventData(obj,evts)
            obj.EventData=evts;
        end
        function [] = plotTimeLine(obj)
            tlc{1}=obj.OptiFileCombined.getTimeline;
            tlc{2}=obj.VideoFilesCombined.getTimeline;
            tlc{3}=obj.OpenEphysRecordCombined.getTimeline;
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
                FigureFactory.instance.save(fullfile(obj.WorkspaceFolder,[obj.Name '-TimeLine']))
            end
        end
        function obj = plotStateDetection(obj,sessionName)
            switch sessionName
                case 'SD'
                    session=obj.OpenEphysRecordCombined.getOpenEphysRecords.get(2);
                otherwise
            end
            %%
            % while iter.hasNext
            sessionStruct=BuzcodeFactory.getBuzcode(session);
            stateDetectionBuzcode=StateDetectionBuzcode();
            stateDetectionBuzcode=stateDetectionBuzcode.setBuzcodeStructer(sessionStruct);
            %     stateDetectionBuzcode.overwriteEMGFromLFP
            stateDetectionData=stateDetectionBuzcode.getStates;
            evttbl=session.getEventTable;
            evtnum=4;
            beforaftnerseconds=10;
            %             timewindow=session.getTimestamps.IsActive.TimeInfo.StartDate+...
            %                 seconds([evttbl(evtnum,2)-beforafterseconds...
            %                 evttbl(evtnum,2)+beforafterseconds]);
            %             obj.VideoFilesCombined.preview(timewindow)
            stateDetectionData.openStateEditor(evttbl,obj)
            %%
            %             filename=fullfile(stateDetectionData.BasePath,'StateScoreFigures',['StateDetector_','zoom']);
            %             for ifigtype=1:numel(figtypes), print(filename, figtypes{ifigtype},'-r300');end
            % end
        end
    end
    methods (Access=private)
        
    end
end

