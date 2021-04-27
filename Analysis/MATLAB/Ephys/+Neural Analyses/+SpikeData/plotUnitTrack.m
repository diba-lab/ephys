function []=plotUnitTrack(su,mldtrack,cfg)
fname='Track Unit Activities';try close(fname);catch, end
f1=figure('Units','normalized','Position',[0.5 0 .40 1],'Name',fname);
subplot(6,1,1:2);
ax=gca;
su.plotOnTimeTrack(mldtrack,5);
subplot(6,1,3);
su.plotOnTrack(mldtrack,5);
subplot(6,1,4);
su.plotPlaceFieldBoth(mldtrack,5);
ylabel('both');
subplot(6,1,5);
su.plotPlaceFieldNeg(mldtrack,-5);ylabel('left');
subplot(6,1,6);
su.plotPlaceFieldPos(mldtrack,5);ylabel('right');
drawnow
ax=gca;
%     ax.Position=[ax.Position(1) ax.Position(2) ax.Position(3)*1.3 ax.Position(4)*1.3];
legend off
box off
[h,m]=hms(cfg.toi);
f=FigureFactory.instance;
f.save(fullfile(cfg.folder,'figures',sprintf('%s, %d:%d-%d:%d,  ID:%d, CH:%d',...
    fname,h(1),m(1),h(2),m(2),su.Id,su.Channel)));
end