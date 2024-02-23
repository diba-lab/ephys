Animal=   {'AF';'AG';'AG';'AE'; 'AG'; 'AG';'AE'; 'AF'};% AE NSD 1 removed
Condition={'SD';'SD';'SD';'SD';'NSD';'NSD';'NSD';'NSD'};
Day=      [  2 ;  1 ;  2 ;  1 ;  1  ;  2  ;  2  ;  1  ];
sesDay=   [  3 ;  1 ;  3 ;  2 ;  2  ;  4  ;  3  ;  2  ];
table1=table(Animal,Condition,Day,sesDay);    sf=experiment.SessionFactory;
sf=experiment.SessionFactory;
ses=table1(6,:);
ses1=sf.getSessions(ses.Animal,ses.Condition,ses.sesDay);
lfp=ses1.getDataLFP;
lfp.TimeIntervalCombined.plot
%%
rippple=lfp.getRippleEvents;
rippple=rippple.getZtAdjustedTbl;
sdd=lfp.getStateDetectionData;
dt=lfp.getChannelTimeDataHard;
bl=ses1.getBlock('TRACK');
th=dt.getChannel(sdd.getThetaChannelID).getTimeWindow(bl);
sw=dt.getChannel(sdd.getSWChannelID).getTimeWindow(bl);
th_f=th.getBandpassFiltered([5 12]);
th_fe=th_f.getEnvelope;
sw_f=sw.getLowpassFiltered(4);
sw_fe=sw_f.getEnvelope;
%%
ss=sdd.getStateSeries;
ss=ss.getWindow(bl);
[tt1,t1]=ss.getState("AWAKE");
tt=[tt1(1,1) tt1(end,2)];
swtemp=sw_fe.getTimeWindow(tt);
figure(1);tl1=tiledlayout(2,2);
tl11=nexttile(tl1,1);
th_f.plot
hold on
% RES.Values=th_fe.Values./sw_fe.Values;
th_fez=th_fe.getZScored;
th_fe.Values(th_fez.Values>1.2)=nan;
th_fe.plot
%%
% sw_f.plot
% sw_fe.plot
yyaxis("left")

tl12=nexttile(tl1,3);cla;
% th_fe.plot;hold on

th_fef=th_fe.getGaussianFiltered(10);
th_fefs=th_fef.getTimeWindow(tt);
p=th_fefs.plot;
pos=ses1.getPosition;
spd=pos.getSpeed(10);
spd=spd.getReSampled(th_fefs.getSampleRate);
spd1=spd.getTimeWindow(tt);
yyaxis("right")
p=spd1.plot('-') ;
% p=spd1.plot({'-k'})

idx=isnan(spd1.Values)|isnan(th_fefs.Values);
corr=xcorr(th_fefs.Values(~idx),spd1.Values(~idx),th_fefs.getSampleRate*60*10);
diffdur=(numel(corr)-1)/2/swtemp.getSampleRate;
% ax=gca;ax.XLim=[336 336.5];
ax1=nexttile(tl1,2,[2 1]);cla;
plot(linspace(-diffdur,diffdur,numel(corr)),corr)
% Create a function handle with additional arguments
rerunFuncHandle = @(src, evt) rerunFunction(src, evt, th_fefs, spd1);
addlistener(tl12,  'XLim', 'PostSet', rerunFuncHandle);

linkaxes([tl11 tl12],'x');

%%

figure
pd1=pdTRACK.getTimeWindow(hours([6.045 6.05])+hours(8));
pd1.getSpeed.plot
hold on
pd1.getSpeed(2).plot
%%
% Define the function to be rerun
function rerunFunction(~, evt, th_fefs, spd1)
newXLim = evt.AffectedObject.XLim;  % Get the updated XLim values
% Replace this with your desired code that should be rerun
wind=minutes(newXLim);
ticd=th_fefs.TimeIntervalCombined;
th_fefs=th_fefs.getTimeWindow(ticd.getZeitgeberTime+wind);
spd1=spd1.getTimeWindow(ticd.getZeitgeberTime+wind);
corr=xcorr(th_fefs.Values(~idx),spd1.Values(~idx), ...
    th_fefs.getSampleRate*seconds(diff(wind))/2);
diffdur=(numel(corr)-1)/2/swtemp.getSampleRate;
plot(linspace(-diffdur,diffdur,numel(corr)),corr)
end
