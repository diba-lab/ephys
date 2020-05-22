classdef Probe < NeuroscopeLayout & SpykingCircusLayout
    
    %PROBE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        Type
        SiteSpatialLayout
        SiteSizesInUm
    end
    
    methods
        function newobj = Probe(probeFile)
            %PROBE Construct an instance of this class
            %   Detailed explanation goes here
            T=load(probeFile);
            newobj.SiteSpatialLayout =T.T_sorted;
            
        end
    end
    methods (Access=public)
        function T = plotProbeLayout(obj,varargin)
            showchannelstxt=0;
            showchannelstxt_highlight=1;
            T=obj.SiteSpatialLayout;
            try
                highlight=varargin{1};
                idx=find(ismember(T.ChannelNumberComingOutPreAmp, highlight));
                colors=linspecer(numel(highlight),'sequential');
                hold on;
                for icolor=1:numel(highlight)
                    p1=plot(T.X(idx(icolor)),T.Z(idx(icolor)),'.',...
                        'MarkerSize',30,...
                        'Color',colors(icolor,:));
                    if showchannelstxt_highlight
                        
                        text(T.X(idx(icolor)),T.Z(idx(icolor)),...
                            num2str(T.ChannelNumberComingOutPreAmp(idx(icolor))),...
                            'FontSize',12,'VerticalAlignment','bottom'...
                            ,'HorizontalAlignment','center')
                    end
                end
            catch
            end
            hold on;
            p1=plot(T.X,T.Z,'.', 'MarkerSize',10);
            p1.MarkerEdgeColor='k';
            p1.LineWidth=1;
            if showchannelstxt
                for i=1:size(T,1)
                    text(T.X(i),T.Z(i),num2str(T.ChannelNumberComingOutPreAmp(i)),...
                        'FontSize',7,'VerticalAlignment','bottom'...
                        ,'HorizontalAlignment','center')
                end
            end
            ax=gca;
            box off
            axis equal
            set(gca,'FontSize',10,'TickDir','out')
            ax.XDir='reverse';
            ax.YDir='reverse';
            lim=axis;
            ax.XTickLabel{1}=[ax.XTickLabel{1} '\mu'];
            axis([lim(1)-50 lim(2)+50 lim(3) lim(4)])
            
        end
    end
    %% GETTER & SETTERS
    methods
        function siteLayout=getSiteSpatialLayout(obj)
            siteLayout=obj.SiteSpatialLayout;
        end
        function obj=getShank(obj,shankNo)
            siteLayout=obj.SiteSpatialLayout;
            obj.SiteSpatialLayout=siteLayout(siteLayout.ShankNumber==shankNo,:);
        end
    end
    
end