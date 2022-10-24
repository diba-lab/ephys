% clear all

sf=experiment.SessionFactory;
animal='AG';
cond='NSD';
sesno=1;
sess=sf.getSessions(animal,cond);
ses=sess(sesno);
ret=ses.getDataLFP.getRippleEvents.getWindow(ses.getBlock('TRACK'));
diff=seconds(seconds(ret.PeakTimes.peak)+ ...
    ret.TimeIntervalCombined.getStartTime- ...
    ret.TimeIntervalCombined.getZeitgeberTime);
%% Units
sa=ses.getUnits;
saTrack=sa.getTimeInterval(ses.getBlock('TRACK')).sort('group');%
% .sort('firingRateGiniCoeff');

susTRACK=saTrack.getSpikeUnits;
ff=logistics.FigureFactory.instance("./pf");
%% position
pd=ses.getPosition;
if isempty(pd.units), pd.units='cm';end
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
for isu=1:numel(susTRACK)
    su=susTRACK(isu);
    % combined
    sut=su+pdss{1};
    if numel(sut.Times)>100
        f=figure('Position',[2616 -149 1500 1500]);
        t=tiledlayout(3,5);t.TileSpacing='tight';
        for isut=1:numel(pdss)
            suts{isut}=su+pdss{isut};
            sut=suts{isut};
            oms{isut}=sut.PositionData.getOccupancyMap;om=oms{isut};
            xlims{isut}=[min(om.PositionData.X) max(om.PositionData.X)];
            ylims{isut}=[min(om.PositionData.Z) max(om.PositionData.Z)];
            frms{isut}=sut.getFireRateMap;
            pfms{isut}=frms{isut}.getPlaceFieldMap;
        end
        nexttile(1,[3,2])
        suts{1}.plotOnTrack3D;
        ax=gca;ax.XLim=xlims{1};ax.YLim=ylims{1};
        len1=[1 1;1 1; 1 1];
        loc=[3 4 5];
        for isut=1:3
            nexttile(loc(isut),len1(isut,:));
            pdss{isut}.plot2D;hold on
            oms{isut}.plotSmooth;
            shape(isut,xlims,ylims,'Occupancy (s)/cm2');
        end
        len1=[1 1;1 1; 1 1];
        loc=[8 9 10];
        for isut=1:3
            nexttile(loc(isut),len1(isut,:));
            suts{isut}.plotSpikes2D;hold on;
            frms{isut}.plotSmooth;
            shape(isut,xlims,ylims,'# of spikes/cm2');
        end
        len1=[1 1;1 1; 1 1];
        loc=[13 14 15];
        for isut=1:3
            nexttile(loc(isut),len1(isut,:));
            pfms{isut}.plotSmooth;
            shape(isut,xlims,ylims,'Fire Rate (Hz)');
        end
        str=fullfile('./pf/',sprintf('%s-d%d-%s-%d',animal,sesno,cond,su.Id));
        ff.save(str);
        close(f)
    end
end
function shape(isut,xlims,ylims,str)
ax=gca;ax.YDir="normal"; ax.XLim=xlims{isut};ax.YLim=ylims{isut};
if isut==3
    ax.DataAspectRatio=[1 .03 1]; ax.YTick=[];ax.YLabel=[];
else
    ax.DataAspectRatio=[1 1 1];
end
cb=colorbar('northoutside');cb.Label.String=str;
end