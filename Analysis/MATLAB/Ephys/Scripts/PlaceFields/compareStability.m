Animal=   {'AG';'AG';'AE'; 'AG'; 'AG'; 'AE';'AE'; 'AF'};% AE NSD 1 removed
Condition={'SD';'SD';'SD';'NSD';'NSD';'NSD';'NSD';'NSD'};
Day=      [   1;   2;   1;    1;    2;    1;    2;    1];
sesDay=   [   1;   3;   2;    2;    4;    1;    3;    2];
table1=table(Animal,Condition,Day,sesDay);
for it=7:height(table1)
    s1=table1(it,:);
%     phaseFile=sprintf('neuro.phase.PhasePrecessionCollection_%s-%s-%d', ...
%         s1.Animal{:},s1.Condition{:},s1.Day);
    placeFile=sprintf('neuro.placeField.PlaceFieldMapCollection_%s-%s-%d', ...
        s1.Animal{:},s1.Condition{:},s1.Day);
    Sp=load(placeFile); pfmc=Sp.pfmc; clear Sp;
    sf=experiment.SessionFactory;
    a=sf.getSessions(s1.Animal,s1.Condition,s1.sesDay);
    pfmc1=pfmc.downsize(fullfile(a.SessionInfo.baseFolder,"placeFieldAnalysisTable.mat"));
    if exist('pfmcall','var')
        pfmcall=pfmcall.add(pfmc);
    else
        pfmcall=pfmc;
    end
end