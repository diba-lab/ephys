
for sesno=2:8
% for sesno=    [     6      ]
    clearvars  -except sesno
    %            1    2    3    4     5     6    7     8    9
    Animal=   {'AF';'AG';'AG';'AE'; 'AG'; 'AG';'AE'; 'AF'};% AE NSD 1 removed
    Condition={'SD';'SD';'SD';'SD';'NSD';'NSD';'NSD';'NSD'};
    Day=      [  2 ;  1 ;  2 ;  1 ;  1  ;  2  ;  2  ;  1  ];
    sesDay=   [  3 ;  1 ;  3 ;  2 ;  2  ;  4  ;  3  ;  2  ];
    table1=table(Animal,Condition,Day,sesDay);    sf=experiment.SessionFactory;
    animal=table1.Animal{sesno};
    cond=table1.Condition{sesno};
    day=table1.sesDay(sesno);
    ses=sf.getSessions(animal ,cond,table1.sesDay(sesno));
%     ses.printProbe;
    baseFolder=ses.SessionInfo.baseFolder;
    cch=cache.Manager.instance(strcat(baseFolder,['/cacheUnits/placeField' ...
        'AnalysisTable.mat']));
    %% theta LFP CSD
    ctdh=ses.getDataLFP.getChannelTimeDataHard;
    if 0
        ticd=ctdh.TimeIntervalCombined;
        wind=ses.Blocks.Date+ses.getBlock('TRACK');
        prb=ctdh.Probe;t=prb.getSiteSpatialLayout;
        shanks=table2array(unique(t(t.isActive==1,"ShankNumber")));
        ff=logistics.FigureFactory.instance(ses.getBasePath);
        csdfile=sprintf('%s-CSD-%s',ses.getBaseName,string(datetime('now')));
        for ishank=1:numel(shanks)
            ch=prb.getShank(ishank).getActiveChannels;
            chtemplate=sort([1:3:31 2:3:29 32]);
            ch=chtemplate+(ishank-1)*32;
            %     st1=ticd.getAbsoluteTime(minutes(790)+seconds(11)+seconds(956)/1000);
            st1=ticd.getAbsoluteTime(minutes(405)+seconds(26)+seconds(109)/1000);
            %     st1=ticd.getAbsoluteTime(minutes(0)+seconds(0)+seconds(1)/1000);
            %     en1=st1+seconds(.1);
            en1=st1 + seconds(2);
            a=ctdh.get(ch, [st1 en1]);
            %     a=a.getHighpassFiltered(100);
            a=a.getLowpassFiltered(20);
            csd=a.getCSD;
            f1=figure;f1.Position=[1720 2038 560 420*2];
            %     csd.plot;clim([-300 300]);
            csd.plot;clim([-1000 1000]);
            title(sprintf('shank %s',string(shanks(ishank))));
            ff.save(csdfile)
            close
        end
    end
    %%
    thetaLFP=ctdh.getChannel( ...
        ses.getDataLFP.getStateDetectionData.SleepScoreLFP.THchanID);
    thetaLFPt= thetaLFP.getTimeWindow(ses.getBlock('TRACK'));
    [cch, keyTheta]=cch.hold(thetaLFPt,thetaLFPt.toString);
    %% Units
    sa=ses.getUnits;
    saTrack=sa.getTimeInterval(ses.getBlock('TRACK')).sort('group');%
    % .sort('firingRateGiniCoeff');
    susTRACK=saTrack.getSpikeUnits;
    %% Figure
    ff=logistics.FigureFactory.instance("./pf1");
    %% position
    pd=ses.getPosition; if isempty(pd.units), pd.units='cm';end
    pd1=pd.getMedianFiltered(3);
    pd2=pd1.getLowpassFiltered(.5);

    figure; tiledlayout('flow');ax(1)=nexttile();pd.plot
    ax(2)=nexttile;pd1.plot
    ax(3)=nexttile;pd2.plot
    linkaxes(ax)

    pdTRACK=pd.getTimeWindow(ses.getBlock('TRACK'));
    pdTRACKman=pdTRACK.getManifold;
    pd1=pdTRACKman.getMedianFiltered(3);
    pd2=pd1.getLowpassFiltered(.5);
    pdTRACKman1D=pd2.get1DData;

    [tbl, idx]=pdTRACKman1D.getUninterruptedRuns(30);
    filtidx=(idx.pos|idx.neg);
    pdsTRACKfastman1D=pdTRACKman1D(filtidx);

    % figure; tiledlayout('flow');ax(1)=nexttile();pdTRACKman.plot
    % ax(2)=nexttile;pd1.plot
    % ax(3)=nexttile;pd2.plot
    % linkaxes(ax)

    pdsTRACKfastman2D=pdTRACKman(filtidx);
    pdsTRACKfast3D=pdTRACK(filtidx);

    % sapos=saTrack+pdsTRACKfastman1D;

    timepositionloc=[1 2];
    pdss{1}=pdsTRACKfast3D;
    pdss{2}=pdsTRACKfastman2D;
    pdss{3}=pdsTRACKfastman1D;
    %% Unit for loop
    pfmc=neuro.placeField.PlaceFieldMapCollection(cch);
    % phpc=neuro.phase.PhasePrecessionCollection(cch);
    f = waitbar(0,'Please wait...');
    for isu=1:numel(susTRACK)
        su=susTRACK(isu);
        if numel(su.TimesInSamples)>50
            % sul=su+thetaLFPt;
            % combined
            pd1D=pdss{3};
            tblpds=pd1D.getTrialsDetected;
            for ipd=1:2
                try
                    sut=su+tblpds.Obj{ipd};
                catch ME

                end
                if numel(sut.TimesInSamples)>50
                    %         f=figure('Position',[2616 -149 1500 1500]);
                    %         t=tiledlayout(3,5);t.TileSpacing='tight';
                    pfms=cell(numel(pdss),1);
                    for isut=1:numel(pdss)
                        if isut==3
                            sut=su+tblpds.Obj{ipd};
                            sut.InfoPosition.direction=tblpds(ipd,:).Direction;
                        else
                            sut=su+pdss{isut};
                        end
                        frm=sut.getFireRateMap;
                        pfms{isut}=frm.getPlaceFieldMap;
                    end
                    pfms{2}.Parent=pfms{1};
                    pfms{3}.Parent=pfms{2};
                    pfmc=pfmc.add(pfms{3});
                    % phpc=phpc.add(sult.thetaPhasePrecession);
                    % figure(Position=[2868 -151 990 1226]);
                    % tiledlayout(4,2,"TileSpacing","tight");
                    % axs(1)=nexttile(1,[4 1]);
                    % axs(2)=nexttile(2,[1 1]);
                    % axs(3)=nexttile(4,[1 1]);
                    % axs(4)=nexttile(6,[1 1]);
                    % axs(5)=nexttile(8,[1 1]);
                    % sult.plot(axs);
                    % txt1=annotation('textbox',[.8 0 .2 .3],'String', ...
                    %     sult.tostring,'VerticalAlignment','bottom');
                    % txt1.LineStyle='none'; txt1.HorizontalAlignment="right";
                    % ff.save(sprintf('%s-%s-d%d',animal, cond, sesno));
                    % close
                end
            end
        end
        waitbar(double(isu)/numel(susTRACK), f, sprintf('%.1f%%', ...
            double(isu)/numel(susTRACK)*100))
    end
    save(['Scripts/PlaceFields/' ...
        sprintf('%s_%s-%s-%d.mat',class(pfmc),animal,cond,day)],"pfmc", ...
        '-v7.3'); clear pfmc;
    % save(['Scripts/PlaceFields/' ...
    %     sprintf('%s_%s-%s-%d.mat',class(phpc),animal,cond,Day)],"phpc", ...
    %     '-v7.3')
    delete(f);
end
%%
tbl=pfmc.getUnitInfoTable;
idx=ismember(tbl.group,'good');% &...
%~ismember(pfmc.getUnitInfoTable.cellType,'Pyramidal Cell')
pftbl=pfmc.getPlaceFieldInfoTable;
%%
idxpf1=pftbl.Information>0.8;
idxpf2=[pftbl.Stability.gini]' >.8;
filter1=idx&idxpf1&idxpf2;
[pfmc1, ind]=pfmc.getUnits(filter1).sortByPeakLocalMaxima;

phpc1=phpc.getUnits(filter1).getUnits(ind);

pfmc1.plot(phpc1);
