clear all
cond={'SD','NSD'};
condcol={[1 0 0],[1 0.6 0.4];[0 0 1],[.4 .6 1]};
sde=experiment.SDExperiment.instance;
        figure;
sf=experiment.SessionFactory;
for icond=1:numel(cond)
     sess=sf.getSessions('AI',cond{icond});
    for ises=1:numel(sess)
        dlfp=preprocessing.Preprocess(sess(ises)).getDataForLFP;
        % dclu=preprocessing.Preprocess(sess(3)).getDataForClustering
        % preprocessing.Preprocess(sess(3)).reCalculateArtifacts;
        buzcode.BuzcodeEvents(dlfp.getRippleEvents).savemat;
        swr=dlfp.getRippleEvents;
        swr.TimeIntervalCombined=swr.TimeIntervalCombined.setZeitgeberTime(sess(ises).SessionInfo.ZeitgeberTime);
        
        hvs=neuro.HVS.HighVoltageSignals( dlfp);
        
        hvsswr=experiment.plot.HVS.HVSSWR(hvs,swr);
        %         dlfp.getStateDetectionData.openStateEditor;
        subplot(4,1,(icond-1)*2+ises)
        xline([0 5.2 6.5],'LineWidth',2);
        hvsswr.plot(condcol{icond,ises});
        
        
        % dcl=pr.getDataForClustering;
    end
end