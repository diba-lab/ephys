function [hit,outputArg2] = updatePlaceFieldPlots(src,hit,obj,t)
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

str=pfm.Parent.Parent.SpikeUnitTracked.tostring;
 % get the handle of the hidden annotation axes
delete(findall(gcf,'Tag','scribeOverlay'));
t1=annotation('textbox','String', str);
t1.Position=[.8 .8 .2 .2;];
t1.VerticalAlignment="top";
t1.HorizontalAlignment="right";
t1.LineStyle="none";
drawnow;

% nexttile(t,3,[2 1]);
% pfm.Parent.Parent.SpikeUnitTracked.plotOnTrack3D;ax=gca;ax.PlotBoxAspectRatio=[1 1 3];
nexttile(t,3,[4 1]);
pfm.Parent.Parent.SpikeUnitTracked.plotOnTrack3D;ax=gca;ax.PlotBoxAspectRatio=[1 1 2];
ax.CameraPosition
hold off;
end

