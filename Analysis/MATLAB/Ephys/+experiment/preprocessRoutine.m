sf=experiment.SessionFactory
sessions=sf.getSessions('AG',5);
% sess={'PRE','SD_NSD','TRACK','POST'};
% ses=sess{3};
for ises=1:numel(sessions)
    theses=sessions(ises);
    pr=preprocessing.Preprocess(theses);
    %     datalfp=theses.getDataLFP;
    dataclu=pr.getDataForClustering;
    for iclu=dataclu
        iclu.runKilosort3
    end
    %
    %     arts=pr.reCalculateArtifacts;
    %     wind=theses.getBlock(ses);
    %     wind=[wind.t1 wind.t2];
    %         arts.plot();
    
    sdd=datalfp.getStateDetectionData;
    %     opripples=datalfp.getRippleEvents;
    
    %     ss=sdd.getStateSeries;
    %     pr.getDataForClustering
end
% f=FigureFactory.instance;
% f.save(ses)

ctd=neuro.basic.ChannelTimeData('/data2/gdrive/ephys/clustering/AG_2020-01-05_SD/shank1/MergedRaw.filtered.dat')