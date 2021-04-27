function xytbin=binpos(xyt,gridsize)
% function xytbin=binpos(xyt,gridsize)
%Change the time increment of xyt to gridsize
%interpolate x and y.
%txy = [t;x;y] 

tbin = linspace(xyt(1,3),xyt(end,3),gridsize);
xbin = interp1(xyt(:,3),xyt(:,1),tbin);
ybin = interp1(xyt(:,3),xyt(:,2),tbin);

xytbin = [xbin;ybin;tbin]';

