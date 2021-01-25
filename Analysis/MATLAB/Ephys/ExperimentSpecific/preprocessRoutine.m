sf=SessionFactory;
sessions=sf.getSessions('AF',1:3);
% sess={'PRE','SD_NSD','TRACK','POST'};
% ses=sess{3};
for ises=1:numel(sessions)
    theses=sessions(ises);
    pr=Preprocess(theses);
    
    arts=pr.reCalculateArtifacts;
    %     wind=theses.getBlock(ses);
    %     wind=[wind.t1 wind.t2];
    %     arts.plot();
    
    datalfp=theses.getDataLFP;
    sdd=datalfp.getStateDetectionData;
    ripples=datalfp.getRippleEvents;
    
    %     ss=sdd.getStateSeries;
    %     pr.getDataForClustering
end
% f=FigureFactory.instance;
% f.save(ses)