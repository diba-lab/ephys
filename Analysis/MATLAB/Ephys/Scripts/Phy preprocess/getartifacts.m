phyf=phy.PHYFolder(['/data1/2022-06-27_SD_CA1_24Hrs/' ...
    '2022-06-27_SD_CA1_24Hrs/' ...
    '2022-06-27_SD_CA1_24Hrscrs-merged-cleaned.GUI']);
sa=phyf.getSpikeArray;
winlenms=5;
binlenms=1;
frsfile=fullfile(phyf.folderPath, ['meanfirerates' num2str(binlenms) 'ms.mat']);
if exist(frsfile,"file")
    load(frsfile)
else
    tsz=sa.getFireRatesMeanZScoredRaw(binlenms*1e-3);
    save(frsfile,"tsz",'-mat','-v7.3')
end
% frss=frs.getWindow(hours([16 16.1]));
tsz.Values=smoothdata(tsz.Values,'gaussian',round(winlenms/binlenms));
tw=tsz.getTimeWindowsAboveThreshold(1.5);
tw.saveForNeuroscope(phyf.folderPath);
tw.saveForClusteringSpyKingCircus(phyf.folderPath);
meanfr.getT
sav=neuro.spike.SpikeArrayVisualize(sa);
sav.plot