% clear all

sf=experiment.SessionFactory;
animal='AG';
cond='NSD';
sesno=1;
sess=sf.getSessions(animal,cond);
ses=sess(sesno);
%% Units
sa=ses.getUnits;
saTrack=sa.getTimeInterval(ses.getBlock('TRACK')).sort('group');%
% .sort('firingRateGiniCoeff');
susTRACK=saTrack.getSpikeUnits;
%% Figure
ff=logistics.FigureFactory.instance("./pf1");
%% position
pd=ses.getPosition; if isempty(pd.units), pd.units='cm';end
pdTRACK=pd.getTimeWindow(ses.getBlock('TRACK'));
pdTRACKman=pdTRACK.getManifold;
pdTRACKman1D=pdTRACKman.get1DData;
pdsTRACKfastman1D=pdTRACKman1D(pdTRACK.getSpeed(2)>10);
pdsTRACKfastman2D=pdTRACKman(pdTRACK.getSpeed(2)>10);
pdsTRACKfast3D=pdTRACK(pdTRACK.getSpeed(2)>10);
timepositionloc=[1 2];
pdss{1}=pdsTRACKfast3D;
pdss{2}=pdsTRACKfastman2D;
pdss{3}=pdsTRACKfastman1D;

pfmc=neuro.placeField.PlaceFieldMapCollection();
%% Unit for loop
f = waitbar(0,'Please wait...');
for isu=1:numel(susTRACK)
    su=susTRACK(isu);
    % combined
    sut=su+pdss{1};
    if numel(sut.TimesInSamples)>100
%         f=figure('Position',[2616 -149 1500 1500]);
%         t=tiledlayout(3,5);t.TileSpacing='tight';
        for isut=1:numel(pdss)
            suts{isut}=su+pdss{isut};
            sut=suts{isut};
            oms{isut}=sut.PositionData.getOccupancyMap;om=oms{isut};
            frms{isut}=sut.getFireRateMap;
            pfms{isut}=frms{isut}.getPlaceFieldMap;
        end
        pfms{2}.Parent=pfms{1};
        pfms{3}.Parent=pfms{2};
        pfmc=pfmc.add(pfms{3});    
    end
    waitbar(double(isu)/numel(susTRACK), f, sprintf('%.1f%%', ...
        double(isu)/numel(susTRACK)*100))
end
save(['Scripts/PlaceFields/' sprintf('%s_%s-%s-%d.mat',class(pfmc),animal,cond,sesno)],"pfmc")
delete(f);
ax=pfmc.sortByPeak.plot;
