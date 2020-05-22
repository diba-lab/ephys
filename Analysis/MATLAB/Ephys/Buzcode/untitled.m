% load('day1.mat')
oerc=dayx.OpenEphysRecordCombined;
evts=dayx.EventData;
oers=oerc.getOpenEphysRecords;
figtypes={'-dpng'};
%%
iter=oers.createIterator;
%%
% while iter.hasNext
session=oers.get(1);
sessionStruct=BuzcodeFactory.getBuzcode(session);
stateDetectionBuzcode=StateDetectionBuzcode(    );
    %     'rejectChannels',192:200 
    %     'SWWeightsName','SWweightsHPC.mat'

stateDetectionBuzcode=stateDetectionBuzcode.setBuzcodeStructer(sessionStruct);
% stateDetectionBuzcode.overwriteSleepScoreMetrics
stateDetectionData=stateDetectionBuzcode.getStates;

tsc=session.getTimestamps;
ts=tsc.IsActive;
tsnew=ts.resample(stateDetectionData.SleepStateStruct.idx.timestamps);
% stateDetectionData.timeSeriesCollection=tsnew;
evts=tsnew.Events;
evttbl=[];
iievt=0;
for ievt=1:numel(evts)
    iievt=iievt+1;
    evt=evts(ievt);
    dif1=datetime(evt.StartDate)-ts.TimeInfo.StartDate;
    try
        evttbl(iievt,:)=[1, seconds(seconds(evt.Time)+dif1)];
    catch
        warning('unknow key.')
    end
end
stateDetectionData.openStateEditor(evttbl,dayx)
%%
filename=fullfile(stateDetectionData.BasePath,'StateScoreFigures',['StateDetector_','zoom']); 
for ifigtype=1:numel(figtypes), print(filename, figtypes{ifigtype},'-r300');end
% end
%%
rest=oers.get(1);
sleepDep=oers.get(2);
track=oers.get(3);
post=oers.get(4);
%%
sessionStruct=BuzcodeFactory.getBuzcode(oers.get(2));
stateDetectionBuzcode=StateDetectionBuzcode();
stateDetectionBuzcode=stateDetectionBuzcode.setBuzcodeStructer(sessionStruct);
stateDetectionData=stateDetectionBuzcode.getStates;
stateDetectionData.openStateEditor
