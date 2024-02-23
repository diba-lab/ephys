function [hit,outputArg2] = updatePlaceFieldPlotsUni(src,hit,obj,pp,t)
%TRIED Summary of this function goes here
%   Detailed explanation goes here

unitno=round(hit.IntersectionPoint(2));
pfm=obj.PlaceFieldMaps(unitno);
nexttile(t,2);
pfm.Parent.Parent.plotSmooth;ax=gca;ax.DataAspectRatio=[1 1 1];

nexttile(t,5);
pfm.Parent.plotSmooth;ax=gca;ax.DataAspectRatio=[1 2 1];
nexttile(t,8);
pfm.plotSmooth;ax=gca;ax.DataAspectRatio=[1 .1 1];
nexttile(t,11);
plot(pfm.Stability.cum);hold on;
plot(pfm.Stability.basecum);legend({'Cumulative FR','Base'}, ...
    Location="northwest");hold off
xlabel('Time Points (30Hz)');
nexttile(t,3,[4 1]);plot(1);

nexttile(t,14);hold off
php=pp.PhasePrecessions(unitno);
php1=php.getPlaceField;
php1.plotStats

nexttile(t,17,[1 2]);
hold off
php1.plotPrecession;
hold off

delete(findall(gcf,'Tag','scribeOverlay'));
if sum(diff(pfm.PositionData.data.X),'omitnan')>0
    %running right
    annotation("arrow",[.4 .6],[.02 .02],"LineWidth",3,"HeadWidth",20);
else
    % left
    annotation("arrow",[.6 .4],[.02 .02],"LineWidth",3,"HeadWidth",20);
end

str=pfm.Parent.Parent.SpikeUnitTracked.tostring;
 % get the handle of the hidden annotation axes
t1=annotation('textbox','String', str);
t1.Position=[.8 .8 .2 .2;];
t1.VerticalAlignment="top";
t1.HorizontalAlignment="right";
t1.LineStyle="none";
drawnow;

% nexttile(t,3,[2 1]);
% pfm.Parent.Parent.SpikeUnitTracked.plotOnTrack3D;ax=gca;ax.PlotBoxAspectRatio=[1 1 3];
nexttile(t,3,[5 1]);
pfm.SpikeUnitTracked.plotOnTrack3D;ax=gca;%ax.PlotBoxAspectRatio=[1 1 5];
ax.View=[0 0 ];
hold off;
end

