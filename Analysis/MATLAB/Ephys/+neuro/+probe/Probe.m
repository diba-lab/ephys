classdef Probe < neuro.probe.NeuroscopeLayout & neuro.probe.SpykingCircusLayout & neuroscope.Neuroscope
    
    %PROBE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        Type
        SiteSpatialLayout
        SiteSizesInUm
        Source
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
                        [~,ind]=sort(datetime({probefile.date}));
                        probefiles = probefile(flip(ind));
                        probefilefinal=probefiles(1);
                        logger.warning('\nMultiple probe files. Selecting the latest.\n  -->\t%s\n\t%s',probefiles.name)
                    else
                        logger.error('\nNo probe file found in\n\t\%s',probeFile);
                    end
                    probeFile=fullfile(probefilefinal.folder,probefilefinal.name);
                end
                
                try % if saved mat table
                    T=load(probeFile);
                    fnames=fieldnames(T);
                    lay =T.(fnames{1});
                catch % if saved csv table
                    
                    opts = detectImportOptions(probeFile,"TextType","string");
                    T=readtable(probeFile,opts);
                    lay=T;
                end
                
            elseif istable( probeFile)% if the table is given
                lay=probeFile;
            elseif isa(probeFile, 'neuro.probe.Probe') % if loaded mat file is not table
                newobj.Type=probeFile.Type;
                newobj.SiteSpatialLayout=probeFile.SiteSpatialLayout;
                newobj.SiteSizesInUm=probeFile.SiteSizesInUm;
                newobj.Source=probeFile.Source;
                probeFile=newobj.Source;
                lay=newobj.SiteSpatialLayout;
            end

            if ~ismember('isActive',lay.Properties.VariableNames)
                lay=[lay table(ones(height(lay),1),'VariableNames',{'isActive'})];
            end
            newobj.SiteSpatialLayout=lay;
            newobj.Source=probeFile;
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
            axis([min(T.X)-150 max(T.X)+150 min(T.Z)-150 max(T.Z)+150])
            
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
            str=sprintf('%d/%d Shanks, %d/%d Channels, %.0f u depht-span, %.0f u x-span.',actsh,allsh,actch,allch,dep,xsp);
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
        function source=getSource(obj)
            source=obj.Source; 
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
            if ~exist('filepath','var')
                filepath=obj.Source;
            end
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
        function [obj, channum]=addANewChannel(obj,chan)
            change=false;
            chan=string(chan);
            siteLayout=obj.SiteSpatialLayout;
            if ismember('Label',siteLayout.Properties.VariableNames)
                siteLayout.Label=string(siteLayout.Label);
                idx=ismember(siteLayout.Label,chan);
                if ~any(idx)
                    change=true;
                end
            else
                change=true;
            end 
            if change
                numels=height(siteLayout);
                idx=numels+1;
                siteLayout.ChannelNumberComingOutFromProbe(idx)=min(siteLayout.ChannelNumberComingOutFromProbe)-1;
                siteLayout.X(idx)=0;
                siteLayout.Y(idx)=0;
                siteLayout.Z(idx)=0;
                siteLayout.ShankNumber(idx)=0;
                siteLayout.ChannelNumberComingOutPreAmp(idx)=max(siteLayout.ChannelNumberComingOutPreAmp)+1;
                siteLayout.isActive(idx)=1;
                siteLayout.Label(idx)=chan;
                obj.SiteSpatialLayout=siteLayout;
            end
            channum=siteLayout.ChannelNumberComingOutPreAmp(idx);
        end
        function [obj, removed]=removeChannel(obj,chan)
            removed=0;
            siteLayout=obj.SiteSpatialLayout;
            if isstring(chan)
                if ismember('Label',siteLayout.Properties.VariableNames)
                    siteLayout.Label=string(siteLayout.Label);
                    idx=ismember(siteLayout.Label,chan);
                end
            else
                idx=ismember(siteLayout.ChannelNumberComingOutPreAmp,chan);
            end
            if any(idx)
                removed=siteLayout.ChannelNumberComingOutPreAmp(idx);
                siteLayout(idx,:)=[];
                obj.SiteSpatialLayout=siteLayout;
            end
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