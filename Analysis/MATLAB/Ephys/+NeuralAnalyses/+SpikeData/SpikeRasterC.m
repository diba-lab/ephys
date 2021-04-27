function [] = SpikeRaster(fileinfo, shankcluster,TimeSeg);
% function [] = SpikeRaster(fileinfo, shankcluster,TimeSeg,cmap,color_scale);
% TimeSeg should be in res units (32552 Hz)
   
    FileBase = [fileinfo.dir '/' fileinfo.name '/' fileinfo.name];
% if nargin<4    
    load([FileBase '.spikeII.mat']);
    

ResInRange = (spike.t>=TimeSeg(1) & spike.t<=TimeSeg(2));

fs = 32552;
cmap = colormap(jet(64));
dc = floor(64/size(shankcluster,2));
for cc=1:size(shankcluster,2)
    MyRes = spike.t(find(ResInRange & ...
        spike.shank==shankcluster(1,cc) & ...
        spike.cluster==shankcluster(2,cc)));
%       plot(repmat(MyRes(:)',2,1)/fs, repmat(cc+[0;.8],1,length(MyRes)),...
%         'Color',cmap(ceil(cc*color_scale),:),'linewidth', 1);hold on
      plot(repmat(MyRes(:)',2,1)/fs, repmat(cc+[0;.8],1,length(MyRes)),...
        'Color',cmap(dc*cc,:),'linewidth', 1);hold on
%     else
%     plot(repmat(MyRes(:)',2,1)/fs, repmat(cc+[0;.8],1,length(MyRes)),...
%         'k', 'linewidth', 1);hold on
%     end
end   

set(gca,'YTick',[1.4:(size(shankcluster,2)+0.4)])

set(gca,'YTickLabel',[1:size(shankcluster,2)+1]);

elc = fileinfo.thetach+1;
%%error('no channel for theta phase detection is specified.');
numch = length(fileinfo.cluq2)*8;
Eeg = readsinglech([FileBase '.eeg'],numch,elc);

er = round(TimeSeg(1)/26):round(TimeSeg(2)/26);
if ~isempty(Eeg)
plot(er/fs*26, Eeg(1+er)/2000 + size(shankcluster,2)+3, 'k', 'linewidth', 0.5);
ylim([0.8 size(shankcluster,2)+5])
end


xlim(TimeSeg/fs);

hold off