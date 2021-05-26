classdef ChannelTimeDataArtifact < neuro.basic.ChannelTimeData
    %COMBINEDCHANNELS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
    end
    
    methods
        function newobj = ChannelTimeDataArtifact(ctd)
            newobj@neuro.basic.ChannelTimeData(ctd.getFilepath);            
        end
        function arts=getArtifacts(obj)
            
            datafile=obj.getFilepath;
            
%             hdr=ft_read_header(datafile)
%             dat=ft_read_data(datafile,'header',hdr,  'begsample',1,'endsample',1e6);
            cfg=[];
            cfg.trialdef.triallength = 500;
            cfg.trialdef.ntrials     =1;
            cfg.trialfun   =  'ft_trialfun_general';
            cfg.dataset     = datafile;
            [cfg] = ft_definetrial(cfg);
            data=ft_preprocessing(cfg);
            cfg.continuous='yes';
            cfg.artfctdef.jump.channel='all';
            cfg.artfctdef.jump.interactive = 'yes';
            [cfg, artifact_jump] =ft_artifact_jump(cfg,data)

            chnames=obj.getChannelNames();
            obj.getChannel
        end
    end
end