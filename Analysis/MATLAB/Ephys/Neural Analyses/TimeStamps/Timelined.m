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
                timelines=varargin{1};
            else
                timelines=obj.getTimeline();
            end
            numrec=1;
            
            if iscell(timelines)
                numrec=numel(timelines);
                hold on;
            end
            
            for itimeline=1:numrec
                if iscell(timelines)
                    timeline=timelines{itimeline};
                else
                    timeline=timelines;
                end
                plot(timeline.TimeInfo.StartDate,double(timeline.Data(1)));
                p1=timeline.plot;
                xtickformat('h:mm:ss');
                p1(1).LineStyle='none';
                p1(1).Marker='.';
                p1(1).MarkerSize=20;
            end
            ax=gca;
            
            ax.XAxisLocation='origin';
            ax.Box='off';
            ax.YTick=[];
            %             ax.XLim=[timeline(1) timeline(end)];
        end
    end
end

