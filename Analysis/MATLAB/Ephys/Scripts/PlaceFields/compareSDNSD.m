    %            1    2    3     4     5     6    7     8    9
    Animal=   {'AF';'AG';'AG';'AE'; 'AG'; 'AG';'AE'; 'AF'};% AE NSD 1 removed
    Condition={'SD';'SD';'SD';'SD';'NSD';'NSD';'NSD';'NSD'};
    Day=      [  2 ;  1 ;  2 ;  1 ;  1  ;  2  ;  2  ;  1  ];
    sesDay=   [  3 ;  1 ;  3 ;  2 ;  2  ;  4  ;  3  ;  2  ];
table1=table(Animal,Condition,Day,sesDay);
for it=1:height(table1)
    s1=table1(it,:);
%     phaseFile=sprintf('neuro.phase.PhasePrecessionCollection_%s-%s-%d', ...
%         s1.Animal{:},s1.Condition{:},s1.Day);
    placeFile=sprintf('neuro.placeField.PlaceFieldMapCollection_%s-%s-%d', ...
        s1.Animal{:},s1.Condition{:},s1.sesDay);
    Sp=load(placeFile); pfmc=Sp.pfmc; clear Sp;
    tpf=pfmc.getPlaceFieldInfoTable; clear pfmc;
    s2=repmat(s1,height(tpf),1);
    tpf1=[tpf s2];
    if it==1
        tallf=tpf1;
    else
        tallf=[tallf;tpf1];
    end
end
%%
for it=1:height(table1)
    s1=table1(it,:);
%     phaseFile=sprintf('neuro.phase.PhasePrecessionCollection_%s-%s-%d', ...
%         s1.Animal{:},s1.Condition{:},s1.Day);
    phaseFile=sprintf('neuro.phase.PhasePrecessionCollection_%s-%s-%d', ...
        s1.Animal{:},s1.Condition{:},s1.Day);
    Sp=load(phaseFile);phpc=Sp.phpc;clear Sp;
    tpp=phpc.getPhasePrecessionInfoTable;clear phpc;
    s2=repmat(s1,height(tpp),1);
    tpp1=[tpp s2];
    if it==1
        tallp=tpp1;
    else
        tallp=[tallp;tpp1];
    end
end
%%
% i1=tall.FiringRate>2;
% f2=tall.FiringRate<15;
i1=tallf.Information>0;
g1=[tallf.Stability.gini]'>0.5;
c11=[tallf.Stability.Corr2R1]'>0;
c21=[tallf.Stability.Corr2R2]'>0;
tall1=tallf(i1&g1&c11&c21,:);
condstr={'NSD','SD'};
for ics=1:numel(condstr)
    conds{ics}=tall1(ismember(tall1.Condition,condstr{ics}),:);
end
colors=colororder;
plot1={'Information','FiringRate','Stability.Corr2R1','Stability.Corr2R2',...
    'Stability.gini'};
figure;    tl=tiledlayout('flow');
for iplot=1:numel(plot1)
    nexttile;
    hold on;
    what=plot1{iplot};
    clear this
    for ic=1:numel(conds)
        try
            this{ic}=conds{ic}.(what);
        catch ME
            what=split(what,'.');
            this{ic}=[conds{ic}.(what{1}).(what{2})]';
        end
        h=histogram(this{ic},'Normalization','cdf');
        h.EdgeAlpha=0;h.NumBins=200;
        title(what); 
    end
    [h,p,ks2stat]=kstest2(this{1},this{2});
    if h
        hstr='different'; 
    else
        hstr='the same'; 
    end
    tl=text(median([this{1};this{2}],"omitnan"),.5, ...
        sprintf('%s\np=%.3f\nk=%.3f',hstr,p,ks2stat) ...
        , VerticalAlignment="bottom" ...
        );
    t1=text(1,2,sprintf('N=%d',numel(this{1})),Color=colors(1,:), ...
        Units="characters");
    t1=text(1,1,sprintf('N=%d',numel(this{2})),Color=colors(2,:), ...
        Units="characters");
    legend(condstr,Location="northwest");
end


%%
ff=logistics.FigureFactory.instance("/home/ukaya/Dropbox (University of " + ...
    "Michigan)/Kaya Sleep Project/Placefield");
% i1=tall.FiringRate>2;
% f2=tall.FiringRate<15;
tallp.median(tallp.median>pi)=tallp.median(tallp.median>pi)-2*pi;

tall1=tallp(i1&g1&c11&c21,:);
condstr={'NSD','SD'};
for ics=1:numel(condstr)
    conds{ics}=tall1(ismember(tall1.Condition,condstr{ics}),:);
end
colors=colororder;
plot1={'CorrR','CorrP','Slope','Intercept','mean','median','var','std',...
    'std0','skewness','skewness0','kurtosis','kurtosis0','Rayleigh_p',...
    'Rayleigh_z','Omnibus_p','Omnibus_z'};
plot1={'mean',};
circularPlots={'mean','median',};
fmain=figure(Position=[3046 424 600 800]);
tl=tiledlayout('flow');
for iplot=1:numel(plot1)
    what=plot1{iplot};
    clear this
    if ~ismember(what,circularPlots)
        nexttile;
    else
        pax=polaraxes(tl);
        pax.Layout.Tile = iplot;
    end
    colorconds={'Blues9','Reds9'};
    color2=colororder;
    savefile=strcat('Preference-',string(datetime("now")));
    for ic=1:numel(conds)
        try
            this{ic}=conds{ic}.(what);
            aniDay{ic}=categorical(strcat(conds{ic}.('Animal'),'-', ...
                num2str(conds{ic}.('Day'))));
        catch ME
            what=split(what,'.');
            this{ic}=[conds{ic}.(what{1}).(what{2})]';
        end
        if ~ismember(what,circularPlots)
            h=histogram(this{ic},'Normalization','cdf');
            h.EdgeAlpha=0;h.NumBins=200;
            hold on;
        else
            ph=neuro.phase.Polar(this{ic});
            ph.plotHist(color2(ic,:));
            hold on;
            anidays=unique(aniDay{ic});
            colors=othercolor(colorconds{ic},numel(anidays)+3);
            [Lia,Locb] = ismember(aniDay{ic},anidays);

            fsub=figure;t2=tiledlayout("flow");
            color1=colors(Locb+3,:);
            [colors,ia,ics]=unique(color1,"rows");
            for ad1=1:numel(anidays)
                nexttile;
                ad=anidays(ad1);
                idx=ismember(aniDay{ic},ad);
                ph1=ph;
                ph1.PolarData=ph1.PolarData(idx);
                ph1.plotHist(colors(ad1,:));
                legend(ad,'Location','southoutside');
            end
            figure(fsub);
            ff.save(savefile);
            close;
            figure(fmain);
%             ph.plotScatter(ax.RLim(2),color1);
        end
        title(what);
    end
    if ismember(what,circularPlots)
        ph.plotPolarColors
        ax=gca;axinset=axes(Position=ax.Position);
        axinset.Position(4)=axinset.Position(4)/8;
        axinset.Position(2)=0.05;
        ph.plotLegendAndColors
        axinset.Box="off";axinset.Color='none';
        axinset.XAxis.Visible="off";axinset.YAxis.Visible="off";
        axes(ax);
    end
    if ~ismember(what,circularPlots)
        [h,p,ks2stat]=kstest2(this{1},this{2});
    else
        ph1=neuro.phase.Polar(this{1});
        ph2=neuro.phase.Polar(this{2});
        [p, ks2stat, K]=ph1.compareKS(ph2);
        h=p<.01;
    end

    if h
        hstr='different'; 
    else
        hstr='the same'; 
    end
    t=text(median([this{1};this{2}],"omitnan"),.5, ...
        sprintf('%s\np=%.3f\nk=%.3f',hstr,p,ks2stat) ...
        , VerticalAlignment="bottom" ...
        );
    t1=text(1,2,sprintf('N=%d',numel(this{1})),Color=colors(1,:),Units= ...
        "characters");
    t1=text(1,1,sprintf('N=%d',numel(this{2})),Color=colors(2,:),Units= ...
        "characters");
    legend(condstr,Location="southeast");
    ff.save(savefile);
    close

end
