classdef (Abstract) Timelined
    %TIMELINED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods (Abstract)
        getTimeline(obj)
    end
    
    methods
        
        function []=plotTimeline(obj,varargin)
            f=gcf;
            f.Units='normalized';
            f.Position=[f.Position(1) f.Position(2) f.Position(4)*2 f.Position(4)/4];
            if nargin>1
                timeline=varargin{1};
            else
                timeline=obj.getTimeline();
            end
            numrec=1;
            type=timeline.Type;
            types=unique(type);
            colors=colororder;

            for itype=1:numel(types)
                atype=timeline(ismember(type,types{itype}),:);
                color=colors(itype,:);
                for itimeline=1:height(atype)
                    rec=timeline(itimeline,:);
                    p1=plot([rec.Start rec.Stop], [itype itype]);hold on
                    p1.Color=[.1 .1 .1];
                    p2=plot([rec.Start rec.Stop], [itype itype]);
                    p2.Color=color;
                    p2.LineWidth=2;
                    xtickformat('HH:mm:ss');
                    p1.LineStyle='none';
                    p1.Marker='.';
                    p1.MarkerSize=20;
                end
            end
            ax=gca;
            ax.YLim=[-1 2];
            ax.XAxisLocation='origin';
            ax.Box='off';
            ax.YTick=[];
            %             ax.XLim=[timeline(1) timeline(end)];
        end
    end
end

