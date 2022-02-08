classdef ChannelTimeDataArtifact < neuro.basic.ChannelTimeDataHard
    %COMBINEDCHANNELS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        data
        cfg
    end
    
    methods
        function newobj = ChannelTimeDataArtifact(ctd,cfg1)
            if isstring(ctd)||ischar(ctd)
                datafile=ctd;
            else
                datafile=ctd.getFilepath;
            end
            newobj@neuro.basic.ChannelTimeDataHard(datafile);
            ft_defaults
            cfg=[];
            if ~exist('cfg1','var')||isempty(cfg1)
%                 cfg.channel=1:10;
                cfg.trialdef.triallength = 60;%seconds(hours(1));
            else
                cfg.channel=cfg1.channel;
                cfg.trialdef.triallength = cfg1.trialdef.triallength;%seconds(hours(1));
            end
            cfg.trialdef.ntrials     = inf;
            cfg.trialfun   =  'ft_trialfun_general';
            cfg.dataset     = newobj.getFilepath;
            cfg.headerformat='neuroscope_bin';
            [cfg] = ft_definetrial(cfg);
            
            cfg.dataformat='neuroscope_bin';
            newobj.data=ft_preprocessing(cfg);
            
            cfg=[];
            cfg.continuous                  ='yes';
            if ~exist('cfg1','var')||isempty(cfg1)
                cfg.artfctdef.jump.channel      ='all';
                cfg.artfctdef.jump.artpadding  =.01;
                cfg.artfctdef.jump.interactive = 'yes';
                
                cfg.artfctdef.clip.channel      ='all';
                cfg.artfctdef.clip.timethreshold =.01;
                cfg.artfctdef.clip.amplthreshold ='1%';
                cfg.artfctdef.clip.pretim        =.02;
                cfg.artfctdef.clip.psttim        =.02;
                cfg.artfctdef.clip.interactive = 'yes';
                
                cfg.artfctdef.zvalue.channel      ='all';
                cfg.artfctdef.zvalue.cutoff     = 50;
                cfg.artfctdef.zvalue.artpadding = .01;
%                 cfg.artfctdef.zvalue.hilbert    ='yes';
%                 cfg.artfctdef.zvalue.bpfilter      = 'yes';
%                 cfg.artfctdef.zvalue.bpfreq        = [500 600];
                cfg.artfctdef.zvalue.interactive = 'yes';
                
                cfg.artfctdef.threshold.channel   = 'all';
                cfg.artfctdef.threshold.bpfilter  = 'no';
                %             cfg.artfctdef.threshold.bpfreq    = [0.3 80];
                %             cfg.artfctdef.threshold.bpfiltord = 4;
                cfg.artfctdef.threshold.range     = 1000;
                %             cfg.artfctdef.threshold.max       = 10000;
                %             cfg.artfctdef.threshold.onset     = value in uV or T, default  inf
                %             cfg.artfctdef.threshold.offset    = value in uV or T, default  inf
            else
                cfg.artfctdef=cfg1.artfctdef;
                cfg.artfctdef.jump.channel      =convertStringsToChars(cfg.artfctdef.jump.channel);
                cfg.artfctdef.jump.interactive  =convertStringsToChars(cfg.artfctdef.jump.interactive );
                
                cfg.artfctdef.clip.channel      =convertStringsToChars(cfg.artfctdef.clip.channel);
                cfg.artfctdef.clip.amplthreshold =convertStringsToChars(cfg.artfctdef.clip.amplthreshold);
                cfg.artfctdef.clip.interactive = convertStringsToChars(cfg.artfctdef.clip.interactive);
                
                cfg.artfctdef.zvalue.channel      =convertStringsToChars(cfg.artfctdef.zvalue.channel );
                cfg.artfctdef.zvalue.hilbert    =convertStringsToChars(cfg.artfctdef.zvalue.hilbert);
                cfg.artfctdef.zvalue.bpfilter      =convertStringsToChars(cfg.artfctdef.zvalue.bpfilter );
                cfg.artfctdef.zvalue.interactive = convertStringsToChars(cfg.artfctdef.zvalue.interactive);
               
                cfg.artfctdef.threshold.channel   =convertStringsToChars(cfg.artfctdef.threshold.channel);
                cfg.artfctdef.threshold.bpfilter  =convertStringsToChars(cfg.artfctdef.threshold.bpfilter);

            end
            
            
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
                try mkdir(fullfile(obj.getFolder,'cache')); catch, end
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
        function twd=getArtifactsZValueRaw(obj,overwrite)
            if ~exist('overwrite','var')
                overwrite=false;
            end
            cfg1.artfctdef.zvalue=[];
            cfg1.artfctdef.zvalue.channel      ='all';
            cfg1.artfctdef.zvalue.cutoff     = 20;
            cfg1.artfctdef.zvalue.artpadding = .01;
            cfg1.artfctdef.zvalue.interactive = 'yes';
            
            %% zvalue
            cachefile=fullfile(obj.getFolder,'cache',[DataHash(cfg1.artfctdef.zvalue) '.mat']);
            try
                load(cachefile,'artifact');
            catch
                %             cfg.artfctdef.zvalue.interactive='yes';
                [~, artifact] = ft_artifact_zvalue(cfg1, obj.data);
                mkdir(fullfile(obj.getFolder,'cache'));
                save(cachefile,'artifact')
            end
            tws1=neuro.time.TimeWindowsSample(artifact);
            twd1=tws1.getDuration(obj.getTimeIntervalCombined.getSampleRate);
            cfg1.artfctdef.zvalue.cutoff     = -20;
            cachefile=fullfile(obj.getFolder,'cache',[DataHash(cfg1.artfctdef.zvalue) '.mat']);
            try
                load(cachefile,'artifact');
            catch
                %             cfg.artfctdef.zvalue.interactive='yes';
                [~, artifact] = ft_artifact_zvalue(cfg1, obj.data);
                mkdir(fullfile(obj.getFolder,'cache'));
                save(cachefile,'artifact')
            end
            tws2=neuro.time.TimeWindowsSample(artifact);
            twd2=tws2.getDuration(obj.getTimeIntervalCombined.getSampleRate);
            twd=twd1+twd2;
            twd=twd.mergeOverlaps(0);
            if overwrite
                twd.saveForNeuroscope(obj.getFolder,'rzval');
            end
        end
        function twd=getArtifactsThreshold(obj,overwrite)
            if ~exist('overwrite','var')
                overwrite=false;
            end
            %% zvalue
            cachefile=fullfile(obj.getFolder,'cache',[DataHash(obj.cfg.artfctdef.threshold) '.mat']);
            try
                load(cachefile,'artifact');
            catch
                %             cfg.artfctdef.zvalue.interactive='yes';
                [~, artifact] = ft_artifact_threshold(obj.cfg, obj.data);
                mkdir(fullfile(obj.getFolder,'cache'));
                save(cachefile,'artifact')
            end
            tws=neuro.time.TimeWindowsSample(artifact);
            twd=tws.getDuration(obj.getTimeIntervalCombined.getSampleRate);
            if overwrite
                twd.saveForNeuroscope(obj.getFolder,'thrd');
            end
        end
        function all=getArtifactsAllCombined(obj,overwrite)
            if ~exist('overwrite','var')
                overwrite=false;
            end
            clip=obj.getArtifactsClip(false);
            jump=obj.getArtifactsJump(false);
            zval=obj.getArtifactsZValue(false);
            zvalr=obj.getArtifactsZValueRaw(false);
            all1=clip+jump+zval+zvalr;
            all=all1.mergeOverlaps(.5);
            if overwrite
                all.saveForNeuroscope(obj.getFolder,'all');
            end
        end
        function all=saveDeadFileForSpyKingCircus(obj)
            all=obj.getArtifactsAllCombined(true);
            all.saveForClusteringSpyKingCircus(obj.getFolder);
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
            obj.getArtifactsZValueRaw(true);
            obj.getArtifactsAllCombined(true);
        end
    end
end