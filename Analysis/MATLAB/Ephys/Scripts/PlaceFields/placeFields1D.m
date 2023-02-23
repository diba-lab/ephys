clear all

sf=experiment.SessionFactory;
animal='AE';

cond='SD';
sesno=1;
sess=sf.getSessions(animal ,cond);
ses=sess(sesno);
baseFolder=ses.SessionInfo.baseFolder;
cch=cache.Manager.instance(strcat(baseFolder,'/placeFieldAnalysisTable.mat'));
%% theta LFP
ctdh=ses.getDataLFP.getChannelTimeDataHard;
thetaLFP=ctdh.getChannel(ses.getDataLFP.getStateDetectionData.SleepScoreLFP.THchanID);
thetaLFPt= thetaLFP.getTimeWindow(ses.getBlock('TRACK'));
[cch, keyTheta]=cch.hold(thetaLFPt,'thetaLFPt');
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

figure; tiledlayout('flow');ax(1)=nexttile();pdTRACKman.plot
ax(2)=nexttile;pd1.plot
ax(3)=nexttile;pd2.plot
linkaxes(ax)

pdsTRACKfastman2D=pdTRACKman(filtidx);
pdsTRACKfast3D=pdTRACK(filtidx);

% sapos=saTrack+pdsTRACKfastman1D;

timepositionloc=[1 2];
pdss{1}=pdsTRACKfast3D;
pdss{2}=pdsTRACKfastman2D;
pdss{3}=pdsTRACKfastman1D;

pfmc=neuro.placeField.PlaceFieldMapCollection();
phpc=neuro.phase.PhasePrecessionCollection();
%% Unit for loop
f = waitbar(0,'Please wait...');
for isu=1:numel(susTRACK)
    su=susTRACK(isu);
    sul=su+thetaLFPt;
    % combined
    pd1D=pdss{3};
    tblpds=pd1D.getTrialsDetected;
    for ipd=1:2
        sult=sul+tblpds.Obj{ipd};
        if numel(sult.TimesInSamples)>50
            %         f=figure('Position',[2616 -149 1500 1500]);
            %         t=tiledlayout(3,5);t.TileSpacing='tight';
            for isut=1:numel(pdss)
                if isut==3
                    suts{isut}=su+tblpds.Obj{ipd};
                else
                    suts{isut}=su+pdss{isut};
                end
                sut=suts{isut};
                oms{isut}=sut.PositionData.getOccupancyMap;om=oms{isut};
                frms{isut}=sut.getFireRateMap;
                pfms{isut}=frms{isut}.getPlaceFieldMap;
            end
            pfms{2}.Parent=pfms{1};
            pfms{3}.Parent=pfms{2};
            pfmc=pfmc.add(pfms{3});
            phpc=phpc.add(sult.thetaPhasePrecession);

            figure(Position=[2868 -151 990 1226]);
            tiledlayout(4,2,"TileSpacing","tight");
            axs(1)=nexttile(1,[4 1]);
            axs(2)=nexttile(2,[1 1]);
            axs(3)=nexttile(4,[1 1]);
            axs(4)=nexttile(6,[1 1]);
            axs(5)=nexttile(8,[1 1]);
            sult.plot(axs);
            ff.save(sprintf('%s-%s-d%d_u%d_d%d',animal, cond, sesno, su.Id,ipd));
            close
        end
    end
    waitbar(double(isu)/numel(susTRACK), f, sprintf('%.1f%%', ...
        double(isu)/numel(susTRACK)*100))
end
save(['Scripts/PlaceFields/' ...
    sprintf('%s_%s-%s-%d.mat',class(pfmc),animal,cond,sesno)],"pfmc", ...
    '-v7.3')
save(['Scripts/PlaceFields/' ...
    sprintf('%s_%s-%s-%d.mat',class(phpc),animal,cond,sesno)],"phpc", ...
    '-v7.3')
delete(f);

%%
idx=ismember(pfmc.getUnitInfoTable.group,'good');% &...
    %~ismember(pfmc.getUnitInfoTable.cellType,'Pyramidal Cell')
pftbl=pfmc.getPlaceFieldInfoTable;
%%
idxpf1=pftbl.Information>0.8; 
idxpf2=[pftbl.Stability.gini]' >.8;
filter1=idx&idxpf1&idxpf2;
[pfmc1, ind]=pfmc.getUnits(filter1).sortByPeakLocalMaxima;

phpc1=phpc.getUnits(filter1).getUnits(ind);

pfmc1.plot(phpc1);
