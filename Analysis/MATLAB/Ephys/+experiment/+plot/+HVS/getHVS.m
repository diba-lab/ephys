sf=experiment.SessionFactory;
sess=sf.getSessions;
ses=sess(23);
dlfp=ses.getDataLFP;
sdd=dlfp.getStateDetectionData;
% theta=sdd.getThetaLFP;
ctd=dlfp.getChannelTimeDataHard;
theta=ctd.getChannel(1);
tf=theta.getTimeFrequencyMap(neuro.tf.TimeFrequencyChronuxMtspecgramc([1 40],[2 1]));
%%
ss=sdd.getStateSeries;
mtf1=tf.getMeanFrequency([6 10]);
mtf1=[0 mtf1' 0 0 0 0];
mtfz1=zscore(mtf1);
idx1=[0 ss.States' 0 0 0]==0 | mtfz1<1;

mtf2=tf.getMeanFrequency([12 40]);
mtf2=[0 mtf2' 0 0 0 0];
mtfz2=zscore(mtf2);
idx2=[0 ss.States' 0 0 0]==0 | mtfz2<1;

mtfz_u=mtfz1;
mtfz2=mtfz1;
mtfz1(idx1)=nan;
mtfz2(idx2)=nan;
mtfz_u(idx1|idx2)=nan;

mftz1=[mtfz_u; mtfz2; mtfz1; ];
save('theta_tfz2.mat','mftz1')
%%
fname='/data1/EphysAnalysis/SleepDeprivationData/AI_2021-08-12_SD/Events/AI_2021-08-12_SD.SWR.evt';
evts_swr=neuro.event.NeuroscopeEvents(fname).get('Type','peak').getTableTypesInColumn.Peak;
evts_swr=[ones(numel(evts_swr),1) evts_swr];
evts_swr=buzcode.BuzcodeEvents(neuro.event.NeuroscopeEvents(fname));


fname='/data1/EphysAnalysis/SleepDeprivationData/AI_2021-08-12_SD/Events/Channel.AU1.evt';
evts_aud=neuro.event.NeuroscopeEvents(fname).get('Type','on').getTableTypesInColumn.On;
evts_aud=[ones(numel(evts_aud),1)*2 evts_aud];

fname='/data1/EphysAnalysis/SleepDeprivationData/AI_2021-08-12_SD/Events/Channel.W02.evt';
evts_wat=neuro.event.NeuroscopeEvents(fname).get('Type','on').getTableTypesInColumn.On;
evts_wat=[ones(numel(evts_wat),1)*3 evts_wat];

events=[evts_swr;evts_aud;evts_wat];

%%
fname='/data1/EphysAnalysis/SleepDeprivationData/AI_2021-08-05_NSD/Events/AI_2021-08-05_NSD.SWR.evt';
evts_swr=neuro.event.NeuroscopeEvents(fname).get('Type','peak').getTableTypesInColumn.Peak;
evts_swr=[ones(numel(evts_swr),1) evts_swr];

% fname='/data1/EphysAnalysis/SleepDeprivationData/AI_2021-08-05_NSD/Events/Channel.AUD.evt';
% evts_aud=neuro.event.NeuroscopeEvents(fname).get('Type','on').getTableTypesInColumn.On;
% evts_aud=[ones(numel(evts_aud),1)*2 evts_aud];
% 
% fname='/data1/EphysAnalysis/SleepDeprivationData/AI_2021-08-05_NSD/Events/Channel.W01.evt';
% evts_wat=neuro.event.NeuroscopeEvents(fname).get('Type','on').getTableTypesInColumn.On;
% evts_wat=[ones(numel(evts_wat),1)*3 evts_wat];

% events=[evts_swr;evts_aud;evts_wat];
events=[evts_swr];
%%
ctdd=neuro.basic.ChannelTimeDataHard('/data2/gdrive/ephys/AI/2021-08-05-Day5-NSD/2021-08-05_09-21-33/organized/MergedRaw_1250Hz');
ctda=preprocessing.ChannelTimeDataArtifact(ctdd);
arts=ctda.getArtifactsAllCombined;
arts_rev=arts.getReverse(seconds(ctda.getTimeIntervalCombined.getNumberOfPoints/ctda.getTimeIntervalCombined.getSampleRate));
ripple.execute([],seconds(table2array(arts_rev.getTimeTable)))