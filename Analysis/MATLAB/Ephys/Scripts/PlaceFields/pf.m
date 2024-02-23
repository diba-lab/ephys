clear all

sf=experiment.SessionFactory;
animal='AG'; 
cond='SD';
sesno=2;
sess=sf.getSessions(animal,cond);
ses=sess(sesno);
ret=ses.getDataLFP.getRippleEvents.getWindow(ses.getBlock('TRACK'));

%% LFP
ctdh=ses.getDataLFP.getChannelTimeDataHard;
thetaLFP=ctdh.getChannel( ...
    ses.getDataLFP.getStateDetectionData.SleepScoreLFP.THchanID);
thetaLFPt=thetaLFP.getTimeWindow(ses.getBlock('TRACK'));
tfm=thetaLFPt.getTimeFrequencyMap(...
    neuro.tf.TimeFrequencyWavelet(5:.5:10));
pow=tfm.getPower(5:.5:10);
%% Units
ff=logistics.FigureFactory.instance("./pf");
sa=ses.getUnits;
saTrack=sa.getTimeInterval(ses.getBlock('TRACK')).sort('group');%
susTRACK=saTrack.getSpikeUnits;
%% position
pd=ses.getPosition;
if isempty(pd.units), pd.units='cm';end
pdTRACK=pd.getTimeWindow(ses.getBlock('TRACK'));
pdTRACKman=pdTRACK.getManifold;
pdTRACKman1D=pdTRACKman.get1DData;
% speedidx=pdTRACK.getSpeed(3)>5;
[tbl, idx]=pdTRACKman1D.getUninterruptedRuns(30);
filtidx=(idx.pos|idx.neg);
pdsTRACKfastman1D=pdTRACKman1D(filtidx);
pdsTRACKfastman2D=pdTRACKman(filtidx);
pdsTRACKfast3D=pdTRACK(filtidx);

saTrackPos=saTrack+pdsTRACKfastman1D;
%%
f=figure(Position=[2560 -1116 1440 2466]);
tiledlayout(8,1);
axs(1)=nexttile(1,[3 1]);
axs(2)=nexttile(4);
axs(3)=nexttile(5);
axs(4)=nexttile(6);
% pdTRACKman1D.plotX(pdTRACK.getSpeed(2));hold on
pdTRACKman1D.plotX();hold on
saTrackPos.plotFiringRates(axs);
ax1=nexttile(7);
thetaLFPt.plot;hold on;thetaLFPtf=thetaLFPt.getBandpassFiltered([5 12]);
thetaLFPtf.plot
phase1=thetaLFPtf.getHilbertPhase;

yyaxis('right');p=pow.getGaussianFiltered(1).plot;p.LineWidth=2;
axes(axs(4));
pow.Values=normalize(pow.Values);
yyaxis('right');p=pow.getGaussianFiltered(1).plot;p.LineWidth=2;
ret.plotHistCount

ax2=nexttile(8);
ret.plotHistCount
yyaxis("right"); hold on; ret.plotScatterTimeZt
linkaxes([axs ax1 ax2],'x');

ff.save(sprintf('%s-d%d-%s__FiringRates',animal, sesno,cond));
close;

figure;    t=tiledlayout(2,1);
a1=nexttile(1);
pdTRACKman1D.plotX
a2=nexttile(2);
pdsTRACKfastman1D.plotX
linkaxes([a1 a2]);
ff.save(sprintf('%s-d%d-%s__position',animal, sesno,cond));close
%% 
timepositionloc=[1 2];
pdss{1}=pdsTRACKfast3D;
pdss{2}=pdsTRACKfastman2D;
pdss{3}=pdsTRACKfastman1D;
for isu=1:numel(susTRACK)
    su=susTRACK(isu);
    % combined
    sut=su+pdss{1};
    if numel(sut.TimesInSamples)>100
        for isut=1:numel(pdss)
            suts{isut}=su+pdss{isut};
            sut=suts{isut};
            oms{isut}=sut.PositionData.getOccupancyMap;om=oms{isut};
            xlims{isut}=om.getXLim;
            ylims{isut}=om.getZLim;
            frms{isut}=sut.getFireRateMap;
            pfms{isut}=frms{isut}.getPlaceFieldMap;
        end
        pfmain=pfms{1};
        corr1=pfmain.calculateStabilityCorr(3);
        info=[corr1.maps.Information];
        pf1d=pfms{3};
%         if any(info>1)&& pf1d.Stability.gini>.6
            f=figure('Position',[2616 -149 1500 1500]);
            t=tiledlayout(4,5);t.TileSpacing='tight';
            nexttile(1,[4,2])
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
            n=nexttile(18);
            pos=n.Position;pos(1)=pos(1)+pos(3)/3;pos(2)=pos(2)+pos(4)/3;
            pos(3)=pos(3)/2;pos(4)=pos(4)/3;
            acc=su.getACC;acc.plotSingle();legend off
            ax=axes('Position',pos);
            p=su.plotWaveform;ax.Box="off";
            ax.Color='none';ax.Visible="off";
            p.LineWidth=1.5;
            c=colororder;
            p.Color=c(2,:);
            str=fullfile('./pf/',sprintf('%s-d%d-%s-%d',animal, ...
                sesno,cond,su.Id));
            ff.save(str);
            close(f)
%         end
    end
end
function shape(isut,xlims,ylims,str)
ax=gca;ax.YDir="normal"; ax.XLim=xlims{isut};ax.YLim=ylims{isut};
if isut==3
    ax.DataAspectRatio=[1 .03 1]; ax.YTick=[];ax.YLabel=[];
else
    ax.DataAspectRatio=[1 1 1];
end
cb=colorbar('southoutside');cb.Label.String=str;
end