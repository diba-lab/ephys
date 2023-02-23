Animal={'AG';'AG';'AE';'AG';'AG';'AE';'AF'};% AE NSD 1 removed
Condition={'SD';'SD';'SD';'NSD';'NSD';'NSD';'NSD'};
Day=[1; 2; 1; 1; 2;  2; 1];
table1=table(Animal,Condition,Day);
for it=6:height(table1)
    s1=table1(it,:);
%     phaseFile=sprintf('neuro.phase.PhasePrecessionCollection_%s-%s-%d', ...
%         s1.Animal{:},s1.Condition{:},s1.Day);
    placeFile=sprintf('neuro.placeField.PlaceFieldMapCollection_%s-%s-%d', ...
        s1.Animal{:},s1.Condition{:},s1.Day);
    Sp=load(placeFile); pfmc=Sp.pfmc; clear Sp;
    pfmc1=pfmc.downsize;
    if exist('pfmcall','var')
        pfmcall=pfmcall.add(pfmc);
    else
        pfmcall=pfmc;
    end
end