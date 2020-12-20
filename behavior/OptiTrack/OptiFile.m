classdef OptiFile < Timelined
    %OPTIFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        file
        table
    end
    methods (Abstract)
        loadData(obj)
        getTimeSeriesX(obj)
        getTimeSeriesY(obj)
        getTimeSeriesZ(obj)
    end
    methods
        function obj = OptiFile()
            %OPTIFILE Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        function [] = plotX(obj)
            plot(obj.getTimeSeriesX);
        end
        function [] = plotY(obj)
            plot(obj.getTimeSeriesY);
        end
        function [] = plotZ(obj)
            plot(obj.getTimeSeriesZ);
        end
        function [] = plot(obj)
            X=obj.getTimeSeriesX;
            X=X-mean(X);
            Y=obj.getTimeSeriesY;
            Y=Y-mean(Y);
            Z=obj.getTimeSeriesZ;
            Z=Z-mean(Z);
            plot(X);hold on;
            plot(Y);
            plot(Z);
            legend({'X','Y','Z'})
        end
        function [] = plot3D(obj)
            
            X=obj.getTimeSeriesX;
            srate=1/(diff(X.Time([1 end]))/numel(X.Time));
            tnew=linspace(X.Time(1),X.Time(end),numel(X.Time)/srate/10);
            X=X-mean(X);
%             X=resample(X,tnew);
            Y=obj.getTimeSeriesY;
            Y=Y-mean(Y);
%             Y=resample(Y,tnew);
            Z=obj.getTimeSeriesZ;
            Z=Z-mean(Z);
%             Z=resample(Z,tnew);
            color=linspecer(numel(X.Time),'sequential');
            plot3(Z.Data,X.Data,Y.Data)
            xlabel('front-back');
            ylabel('left-right');
            zlabel('up-down');
%             for iMarker=1:numel(X.Time)
%                 p1=plot3(X.Data(iMarker),Y.Data(iMarker),Z.Data(iMarker));hold on;
%                 p1.LineStyle='none';
%                 p1.Marker='.';
%                 p1.MarkerFaceColor=color(iMarker,:);
%                 p1.MarkerEdgeColor=color(iMarker,:);
% %                 drawnow
%             end
            legend({'TRACK'})
        end
        
        function newOptiFileCombined = plus(obj,optiFileToAdd)
            newOptiFileCombined=OptiFileCombined(obj,optiFileToAdd);
        end
        function ts = getTimestamps(obj)
            startDate=obj.CaptureStartTime;
            tl=obj.getTime;
            ts=timeseries(true(numel(tl),1),tl,'Name','IsActive');
            ts.TimeInfo.StartDate=startDate;
        end
        function chans = getChannels(obj,vars)
            t=obj.table;
            if ~exist('vars','var')
                vars=t.Properties.VariableNames;
            end
            for iDimension=1:numel(vars)
                dim=vars{iDimension};
                aDim=t.(dim);
                aChan= Channel(dim, aDim, obj.getTimeInterval);
                chans.(dim)=aChan;
            end
        end
        function ts = getTimeline(obj)
            ts=obj.getTimestamps;
            step=diff([ts.Time(1) ts.Time(end)])/numel(ts.Time);
            newtime=linspace(ts.Time(1),ts.Time(end),1000);
            ts=ts.resample(newtime);
            ts=ts.addsample('Data',false,'Time',ts.Time(1)-step);
            ts=ts.addsample('Data',false,'Time',ts.Time(end)+step);
        end
        function ti = getTimeInterval(obj)
            ti=TimeInterval(obj.CaptureStartTime, obj.ExportFrameRate,  obj.TotalExportedFrames);
        end
    end
end

