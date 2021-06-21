classdef ChannelTimeDataArtifact < neuro.basic.ChannelTimeData
    %COMBINEDCHANNELS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        data
        cfg
    end
    
    methods
        function newobj = ChannelTimeDataArtifact(ctd)
            if isstring(ctd)||ischar(ctd)
                datafile=ctd;
            else
                datafile=ctd.getFilepath;
            end
            newobj@neuro.basic.ChannelTimeData(datafile);
            ft_defaults
            cfg=[];
            cfg.trialdef.triallength = seconds(hours(3));
            cfg.trialdef.ntrials     =inf;
            cfg.trialfun   =  'ft_trialfun_general';
            cfg.dataset     = newobj.getFilepath;
            cfg.headerformat='openephys_binary';
            [cfg] = ft_definetrial(cfg);
            cfg.dataformat='openephys_binary';
            newobj.data=ft_preprocessing(cfg);
            
            cfg=[];
            cfg.continuous                  ='yes';
            cfg.artfctdef.jump.channel      ='all';
            cfg.artfctdef.jump.interactive  = 'no';
            cfg.artfctdef.jump.artpadding  =.01;
            
            cfg.artfctdef.clip.channel      ='all';
            cfg.artfctdef.clip.timethreshold =.01;
            cfg.artfctdef.clip.amplthreshold ='1%';
            cfg.artfctdef.clip.pretim        =.02;
            cfg.artfctdef.clip.psttim        =.02;
            
            cfg.artfctdef.zvalue.channel      ='all';
            cfg.artfctdef.zvalue.cutoff     = 20;
            cfg.artfctdef.zvalue.artpadding = .01;
            cfg.artfctdef.zvalue.hilbert    ='yes';
            cfg.artfctdef.zvalue.bpfilter      = 'yes';
            cfg.artfctdef.zvalue.bpfreq        = [300 600];
            newobj.cfg=cfg;
        end
        function twd=getArtifactsJump(obj,overwrite)
            if ~exist('overwrite','var')
                overwrite=false;
            end
            %% jump
            cachefile=fullfile(obj.getFolder,'cache',[DataHash(obj.cfg.artfctdef.jump) '.mat']);
            try
                load(cachefile,'artifact');
            catch
                [~, artifact] = ft_artifact_jump(obj.cfg,obj.data);
                mkdir(fullfile(obj.getFolder,'cache'));
                save(cachefile,'artifact')
            end
            tws=neuro.time.TimeWindowsSample(artifact);
            twd=tws.getDuration(obj.getTimeIntervalCombined.getSampleRate);
            if overwrite     
                twd.saveForNeuroscope(obj.getFolder,'jump');
            end
        end
        function twd=getArtifactsClip(obj,overwrite)
            if ~exist('overwrite','var')
                overwrite=false;
            end
            %% clip
            cachefile=fullfile(obj.getFolder,'cache',[DataHash(obj.cfg.artfctdef.clip) '.mat']);
            try
                load(cachefile,'artifact');
            catch
                [~, artifact] = ft_artifact_clip(obj.cfg, obj.data);
                mkdir(fullfile(obj.getFolder,'cache'));
                save(cachefile,'artifact')
            end
            tws=neuro.time.TimeWindowsSample(artifact);
            twd=tws.getDuration(obj.getTimeIntervalCombined.getSampleRate);
            if overwrite     
                twd.saveForNeuroscope(obj.getFolder,'clip');
            end
        end
        function twd=getArtifactsZValue(obj,overwrite)
            if ~exist('overwrite','var')
                overwrite=false;
            end
            %% zvalue
            cachefile=fullfile(obj.getFolder,'cache',[DataHash(obj.cfg.artfctdef.zvalue) '.mat']);
            try
                load(cachefile,'artifact');
            catch
                %             cfg.artfctdef.zvalue.interactive='yes';
                [~, artifact] = ft_artifact_zvalue(obj.cfg, obj.data);
                mkdir(fullfile(obj.getFolder,'cache'));
                save(cachefile,'artifact')
            end
            tws=neuro.time.TimeWindowsSample(artifact);
            twd=tws.getDuration(obj.getTimeIntervalCombined.getSampleRate);
            if overwrite
                twd.saveForNeuroscope(obj.getFolder,'zval');
            end
        end
        function all=getArtifactsAllCombined(obj,overwrite)
            if ~exist('overwrite','var')
                overwrite=false;
            end
            clip=obj.getArtifactsClip(false);
            jump=obj.getArtifactsJump(false);
            zval=obj.getArtifactsZValue(false);
            all1=clip+jump+zval;
            all=all1.mergeOverlaps(.5);
            if overwrite
                all.saveForNeuroscope(obj.getFolder,'all');
            end
        end
        function all=saveDeadFileForSpyKingCircus(obj)
            all=obj.getArtifactsAllCombined();
            all.saveForClusteringSpyKingCircus(obj.getFolder);
            all.saveForNeuroscope(obj.getFolder,'all');
        end
        function []=plot(obj,ax)
            if ~exist('ax','var')
                try close(1);catch, end;figure(1);
                ax=gca;
            end
            colors=get(gca,'colororder');
            c=obj.getArtifactsClip(false);
            subplot(4,1,1)
            c.plotHist(gca,colors(1,:))
            title('Clip');
            j=obj.getArtifactsJump(false);
            subplot(4,1,2)
            j.plotHist(gca,colors(2,:))
            title('Jump');
            z=obj.getArtifactsZValue(false);
            subplot(4,1,3);
            z.plotHist(gca,colors(3,:))
            title('Z-value');
            a=obj.getArtifactsAllCombined(false);
            subplot(4,1,4)
            a.plotHist(gca,colors(4,:))
            title('All');
            xlabel('Artifact Duration');
    
            f=logistics.FigureFactory.instance(obj.getFolder);
            f.save('artifact_hist')
            try close(2);catch, end;figure(2);
            subplot(2,1,1);
            hold on
            c.plotScatter(gca,colors(1,:));
            j.plotScatter(gca,colors(2,:));
            z.plotScatter(gca,colors(3,:));
            ax=gca;ax.YTick=[];
            subplot(2,1,2);
            a.plotScatter(gca,colors(4,:));
            ax=gca;ax.YTick=[];
            f.save('artifact_scatter')
        end
        function []=saveArtifactsForNeuroscope(obj)
            obj.getArtifactsClip(true);
            obj.getArtifactsJump(true);
            obj.getArtifactsZValue(true);
            all=obj.getArtifactsAllCombined;
            all.saveForNeuroscope(obj.getFolder,'all');
        end
    end
end