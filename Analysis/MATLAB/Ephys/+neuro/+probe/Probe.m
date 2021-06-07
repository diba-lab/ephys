classdef Probe < neuro.probe.NeuroscopeLayout & neuro.probe.SpykingCircusLayout & neuroscope.Neuroscope
    
    %PROBE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        Type
        SiteSpatialLayout
        SiteSizesInUm
    end
    
    methods
        function newobj = Probe(varargin)
            %PROBE Construct an instance of this class
            %   Detailed explanation goes here
            probeFile=varargin{1};
            logger=logging.Logger.getLogger;
            % load table
            if isstring(probeFile)||ischar(probeFile)
                
                if isfolder(probeFile)
                    probefile=dir(fullfile(probeFile,sprintf('*Probe*')));
                    if numel(probefile)==1
                        probefilefinal=probefile;
                    elseif numel(probefile)>1
                        [~,ind]=sort({probefile.date});
                        probefiles = probefile(ind);
                        probefilefinal=probefiles(1);
                        logger.warning('\nMultiple probe files. Selecting the latest.\n  -->\t%s\n\t%s',probefiles.name)
                    else
                        logger.error('\nNo probe file found in\n\t\%s',el);
                    end
                    probeFile=fullfile(probefilefinal.folder,probefilefinal.name);
                end
                
                try % if saved mat table
                    T=load(probeFile);
                    fnames=fieldnames(T);
                    lay =T.(fnames{1});
                catch % if saved csv table
                    T=readtable(probeFile);
                    lay=T;
                end
                
            elseif istable( probeFile)% if the table is given
                lay=probeFile;
            end
            if isa(lay, 'Probe') % if loaded mat file is not table
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
        function str=toString(obj)
            t=obj.SiteSpatialLayout;
            actch=sum(t.isActive);
            allch=height(t);
            sh=t.ShankNumber;
            actsh=numel(unique(sh(find(t.isActive))));
            allsh=numel(unique(sh));
            dep=max(t.Z)-min(t.Z);
            xsp=max(t.X)-min(t.X);
            str=sprintf('%d/%d Shanks, %d/%d Channels, %d u depht-span, %d u x-span.',actsh,allsh,actch,allch,dep,xsp);
        end
        function siteLayout=getSiteSpatialLayout(obj,chans)
            if ~exist('chans','var')
                siteLayout=obj.SiteSpatialLayout;
            else
                idx=ismember(obj.SiteSpatialLayout.ChannelNumberComingOutPreAmp,chans);
                siteLayout=obj.SiteSpatialLayout(idx,:);
            end
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
            writetable(siteLayout,filepath);
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