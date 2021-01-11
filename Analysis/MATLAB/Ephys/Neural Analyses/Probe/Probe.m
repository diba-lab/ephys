classdef Probe < NeuroscopeLayout & SpykingCircusLayout & Neuroscope
    
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
            if istable( probeFile)
                lay=probeFile;
            else
                try
                    T=load(probeFile);
                    fnames=fieldnames(T);
                    lay =T.(fnames{1});
                catch
                    T=readtable(probeFile);
                    lay=T;
                end
            end
            if isa(lay, 'Probe')
                probe=lay;
                newobj=probe;
                lay=probe.SiteSpatialLayout;
            end
            if ~ismember('isActive',lay.Properties.VariableNames)
                lay=[lay table(ones(height(lay),1),'VariableNames',{'isActive'})];
            end
            newobj.SiteSpatialLayout=lay;
        end
    end
    methods (Access=public)
        function [T,color1] = plotProbeLayout(obj,varargin)
            showchannelstxt=0;
            showchannelstxt_highlight=1;
            T=obj.SiteSpatialLayout;
            try
                highlight=varargin{1};
                idx=find(ismember(T.ChannelNumberComingOutPreAmp, highlight));
                hold on;
                for icolor=1:numel(highlight)
                    color1(icolor,:)=obj.getColorForDepth(T.Z(idx(icolor)));
                    p1=plot(T.X(idx(icolor)),T.Z(idx(icolor)),'.',...
                        'MarkerSize',30,...
                        'Color',color1(icolor,:));
                    if showchannelstxt_highlight
                        
                        text(T.X(idx(icolor)),T.Z(idx(icolor)),...
                            num2str(T.ChannelNumberComingOutPreAmp(idx(icolor))),...
                            'FontSize',9,'VerticalAlignment','middle'...
                            ,'HorizontalAlignment','right')
                    end
                end
            catch
            end
            hold on;
            active=T.isActive==1;
            
            p1=plot(T.X,T.Z,'.', 'MarkerSize',7);
            p1.MarkerEdgeColor=[.5 .5 .5];
            
            p1=plot(T.X(active),T.Z(active),'.', 'MarkerSize',10);
            p1.MarkerEdgeColor='k';
            if showchannelstxt
                for i=1:size(T,1)
                    text(T.X(i),T.Z(i),num2str(T.ChannelNumberComingOutPreAmp(i)),...
                        'FontSize',7,'VerticalAlignment','middle'...
                        ,'HorizontalAlignment','right')
                end
            end
            ax=gca;
            box off
            axis equal
            set(gca,'FontSize',10,'TickDir','out')
            ax.XDir='reverse';
            ax.YDir='reverse';
            %             ax.YLim=[-100 400];
            lim=axis;
            %             ax.XTickLabel{1}=[ax.XTickLabel{1} '\mu'];
            axis([lim(1)-50 lim(2)+50 -100 400])
            
        end
    end
    %% GETTER & SETTERS
    methods
        function siteLayout=getSiteSpatialLayout(obj)
            siteLayout=obj.SiteSpatialLayout;
        end
        function siteLayout=getActiveChannels(obj)
            siteLayout=obj.SiteSpatialLayout;
            siteLayout=siteLayout.ChannelNumberComingOutPreAmp(siteLayout.isActive==1,:);
        end
        function obj=getShank(obj,shankNo)
            siteLayout=obj.SiteSpatialLayout;
            activeIdx=siteLayout.isActive==1;
            chanidx=ismember(siteLayout.ShankNumber,shankNo);
            chans= siteLayout.ChannelNumberComingOutPreAmp(chanidx&activeIdx);
            obj=obj.setActiveChannels(chans);
        end
        function obj=saveProbeTable(obj,filepath)
            siteLayout=obj.SiteSpatialLayout;
            [folder,name,ext]=fileparts(filepath);
            if ~isfolder(folder),mkdir(folder);end
            writetable(siteLayout,filepath,'replacefile');
        end
        function obj=setActiveChannels(obj,chans)
            siteLayout=obj.SiteSpatialLayout;
            siteLayout.isActive(:)=0;
            try
                siteLayout.isActive(ismember(siteLayout.ChannelNumberComingOutPreAmp,chans))=1;
            catch
                siteLayout.isActive(:)=0;
            end
            obj.SiteSpatialLayout=siteLayout;
        end
        function obj=renameChannelsByOrder(obj,chans)
            siteLayout=obj.SiteSpatialLayout;
            older=chans;
            siteLayout.ChannelNumberComingOutPreAmp(...
                ~ismember(siteLayout.ChannelNumberComingOutPreAmp,chans))=nan;
            [~,idx]=ismember(chans,siteLayout.ChannelNumberComingOutPreAmp);
            new=1:numel(chans);
            siteLayout.ChannelNumberComingOutPreAmp(idx)=new;
            
            obj.SiteSpatialLayout=siteLayout;
        end
        function obj=addActiveChannels(obj,chans)
            siteLayout=obj.SiteSpatialLayout;
            siteLayout.isActive(ismember(siteLayout.ChannelNumberComingOutPreAmp,chans))=1;
            obj.SiteSpatialLayout=siteLayout;
        end
        function obj=removeActiveChannels(obj,chans)
            siteLayout=obj.SiteSpatialLayout;
            siteLayout.isActive(ismember(siteLayout.ChannelNumberComingOutPreAmp,chans))=0;
            obj.SiteSpatialLayout=siteLayout;
        end
    end
    methods (Access=private)
        function color=getColorForDepth(obj,val)
            colors=linspecer(100,'sequential');
            T=obj.SiteSpatialLayout;
            depths=unique(T.Z);
            coloridxes=round(normalize(depths,'range')*99)+1;
            color=colors(coloridxes(  depths==val),:);
        end
    end
    %%abstract
    methods
        function saveObject(obj)
            obj.saveProbeTable(obj.FileLocation)
        end
    end
end