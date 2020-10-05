basepath1='/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day01_SD/04-01-10_18-45-27_down-sampled-1250'
basename1=[basepath1 filesep '04-01-10_18-45-27_down-sampled-1250']
% bz_getSessionInfo(basepath,'editGUI',true)
ignore_times=seconds([
    minutes(0)+seconds(195) seconds(220);
    minutes(540)+seconds(50) minutes(541)+seconds(40);
    minutes(572)+seconds(8) minutes(572)+seconds(20);
    ]);
SleepScoreMaster(basepath1,'ignoretime',ignore_times,'SWChannels',71,'ThetaChannels',71,'overwrite',false)
TheStateEditor(basename1)

basepath2='/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day02_NSD/continuous_05-00-08_18-27-11_down-sampled-1250'
basename2=[basepath2 filesep 'continuous_05-00-08_18-27-11_down-sampled-1250']
SleepScoreMaster(basepath2,'ignoretime',[],'SWChannels',71,'ThetaChannels',71,'overwrite',false)
bz_getSessionInfo(basepath2,'editGUI',true)
TheStateEditor(basename2)