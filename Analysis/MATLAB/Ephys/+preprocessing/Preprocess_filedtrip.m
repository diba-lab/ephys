sdl=experiment.SDLoader_light.instance;
d1=sdl.getRat_AG_Day01_SD;
oerc=d1.OpenEphysRecordCombined;
%%
chSelOneShank=[18 6 29 2 24 22];
combined=[chSelOneShank+32*3 chSelOneShank+32*2 chSelOneShank+32 ...
    chSelOneShank chSelOneShank+32*5 chSelOneShank+32*4];% 
filename=oerc.mergeBlocksOfChannels(combined,d1.WorkspaceFolder);
% probe=oerc.getProbe;
% close;probe.plotProbeLayout(combined)
[path,name,ext]=fileparts(filename);
list=dir(fullfile(path,[name '*Probe*'] ));
probe=Probe(fullfile(list(1).folder,list(1).name));
list=dir(fullfile(path,[name '*Time*'] ));
s=load(fullfile(list(1).folder,list(1).name));fnames=fieldnames(s);
ticd=s.(fnames{1});

data=bz_LoadBinary(filename,'frequency',ticd.getSampleRate,'nChannels',...
numel(probe.getActiveChannels));

%%
lfp.label=strsplit(num2str(1:numel(probe.getActiveChannels)))';
lfp.time={seconds(ticd.getTimePoints)'};
lfp.trial={double(data')};clear data
lfp.fsample=ticd.getSampleRate;
cfg=[];

cfg.continuous= 'yes' ;
% cfg.hpfilter= 'yes';
% cfg.hpfreq = .1;
% cfg.detrend= 'yes';
data1=ft_preprocessing(cfg,lfp);
%%
cfg=[];
cfg.artfctdef.zvalue.channel='all';
cfg.artfctdef.zvalue.cutoff=20;
cfg.artfctdef.jump.trlpadding=0;
cfg.artfctdef.jump.fltpadding=0;
cfg.artfctdef.zvalue.artpadding=0.1;

% algorithmic parameters
cfg.artfctdef.zvalue.cumulative = 'yes';
cfg.artfctdef.zvalue.medianfilter = 'yes';
cfg.artfctdef.zvalue.medianfiltord = 9;
cfg.artfctdef.zvalue.absdiff = 'yes';
cfg.memory = 'low';
% cfg.artfctdef.zvalue.artfctpeak  = 'yes' or 'no'
cfg.artfctdef.zvalue.interactive = 'yes';
clearvars -except cfg data1

[cfg, artifact] = ft_artifact_zvalue(cfg, data1);
%%
cfg=[];
  cfg.continuous = 'yes';
% The following configuration options can be specified
  cfg.artfctdef.threshold.channel   = 'all';
  cfg.artfctdef.threshold.bpfilter  = 'yes';
  cfg.artfctdef.threshold.bpfreq    = [1 30];
  cfg.artfctdef.threshold.bpfiltord = 4;

% It is also possible to use other filter (lpfilter, hpfilter, bsfilter, dftfilter or
% medianfilter) instead of a bpfilter for preprocessing, see FT_PREPROCESSING.

% The detection of artifacts is done according to the following settings,
% you should specify at least one of these thresholds
  cfg.artfctdef.threshold.range     = 1e6;
%   cfg.artfctdef.threshold.min       = value in uV or T, default -inf
  cfg.artfctdef.threshold.max       = .1;
%   cfg.artfctdef.threshold.onset     = value in uV or T, default  inf
%   cfg.artfctdef.threshold.offset    = value in uV or T, default  inf
cfg.artfctdef.threshold.interactive = 'yes';

[cfg, artifact] = ft_artifact_threshold(cfg, data1);
%%
cfg=[];
cfg.artfctdef.threshold.hpfilt='yes';
cfg.artfctdef.threshold.hpfreq=0.1;
% cfg.artfctdef.threshold.min= 
% cfg.artfctdef.threshold.max= 