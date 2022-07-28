classdef PositionData
    %LOCATIONDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data
        timeIntervalCombined
        units
        source
    end
    
    methods
        function obj = PositionData(X,Y,Z,ticd)
            %LOCATIONDATA Construct an instance of this class
            %   ticd should be in TimeIntervalCombined foormat
            if (isstring(X)||ischar(X))&&isfolder(X)
                obj=obj.loadPlainFormat(X);
            elseif isa(X,'optiTrack.PositionData')
                obj.data=X.data;
                obj.timeIntervalCombined=X.timeIntervalCombined;
                obj.units=X.units;
                obj.source=X.source;
            elseif numel(X)==numel(Y)&&numel(Z)==numel(Y)&&numel(X)==ticd.getNumberOfPoints
                data(1,:)=X;
                data(2,:)=Y;
                data(3,:)=Z;
                obj.data=array2table(data','VariableNames',{'X','Y','Z'});
                obj.timeIntervalCombined = ticd;
                obj.units='cm';
            else
                error('Sizes of XYZ or time are not equal.')
            end
        end
        function pd=getWindow(obj,plsd)
            ticd=obj.timeIntervalCombined;
            pd=obj;
            window=ticd.getTimeIntervalForTimes(plsd);
            pd.timeIntervalCombined=window;
            samples=ticd.getSampleForClosest(plsd);
            idx=samples(1):samples(2);
            pd.data=obj.data(idx,:);
        end
        function pd=plus(obj,pd)
            ticd=obj.timeIntervalCombined;
            pd=obj;
            window=ticd.getTimeIntervalForTimes(plsd);
            pd.timeIntervalCombined=window;
            samples=ticd.getSampleForClosest(plsd);
            idx=samples(1):samples(2);
            pd.data=obj.data(idx,:);
        end
        function mat=flatten2(obj)
            mat=obj.data(1:2,:);
        end
        function mat=flatten3(obj)
            mat=obj.data(1:3,:);
        end

        function pdman=getManifold(obj)
            try close(123);catch,end; figure(123);
            c.numberOfPoints=200;
            c.neighbors=7;
            obj1=obj.getDownsampled(obj.timeIntervalCombined.getSampleRate*2);
            spd=obj1.getSpeed.Values;
            [~,I]=sort(spd,'descend');

            manifold = external.Manifold.Manifold("Description");
%             subpd=obj.getWindow(wind);
%             data=table2array(subpd.data)';
            data1=table2array(obj1.data)';
            data2=data1(:,I(1:(size(data1,2)/10)));
            subplot(2,2,1);obj.plot3D;
            subplot(2,2,2);hold on;
            manifold=manifold.createGraph(data2 , ...
                'verbose', ...
                'neighbors', c.neighbors, ...
                'numPoints', c.numberOfPoints ...
                );
            manifold.plotGraph
            manifold=manifold.shortestPath('verbose');
            subplot(2,2,4);hold on;
            manifold=manifold.scale('plot','sammon');
%             manifold=manifold.scale('plot','classical');
            pdman=optiTrack.PositionDataManifold(obj,manifold);
            pdman.config=c;
            subplot(2,2,3);pdman.plotMapped

        end
        
        function [vel]= getSpeed(obj)
            data1=table2array(obj.data)';
            dt=diff(obj.timeIntervalCombined.getTimePointsInSec);
            for idim=1:size(data1,1)
                speed2(idim,:)=diff(data1(idim,:)).^2;
            end
            v=sqrt(sum(speed2,1))./dt;
            vel=neuro.basic.Channel('Velocity',[0 v],obj.timeIntervalCombined);
        end
        function ax = plot(obj)
            numPointsInPlot=100000;
            ticd=obj.timeIntervalCombined;
            t_org=ticd.getTimePointsInSec-seconds(ticd.getZeitgeberTime-ticd.getStartTime);
            downsamplefactor=round(numel(t_org)/numPointsInPlot);
            data1=table2array(obj.data)';
            for ich=1:size(data1,1)
                data2(ich,:)=downsample(medfilt1(data1(ich,:),ticd.getSampleRate),downsamplefactor); %#ok<AGROW> 
            end
            t=hours(seconds(downsample(t_org,downsamplefactor)));
            vel=obj.getSpeed.getMeanFiltered(1);
            vel1=downsample(vel.Values,downsamplefactor);
            scatter(t,data2,vel1*5,'filled','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2,'SizeData',5);
            legend(obj.data.Properties.VariableNames);
            xlabel('ZT (Hrs)');
            ylabel(['Location (',obj.units,')']);
            ax=gca;
        end
        function ax = plot2D(obj)
            numPointsInPlot=200000;
            ticd=obj.timeIntervalCombined;
            t_org=ticd.getTimePointsInSec;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);
            dims=obj.data.Properties.VariableNames;
            if numel(dims)>2
                dims=dims(1:2);
            end
            data1=table2array(obj.data(:,dims))';
            for ich=1:size(data1,1)
                data2(ich,:)=downsample(medfilt1(data1(ich,:),ticd.getSampleRate),downsamplefactor); %#ok<AGROW> 
            end
            color1=linspecer(size(data2,2));
            scatter(data2(1,:),data2(2,:),[],color1,'filled','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2,'SizeData',5);
            ylabel(dims{2});
            xlabel(dims{1});
            ax=gca;
            ax.DataAspectRatio=[1 1 1];
            colormap(color1)
            cb=colorbar;cb.Ticks=[0 1];cb.TickLabels={'Earlier','Later'};cb.Location='north';
            cb.Position(1)=cb.Position(1)+cb.Position(3)/3*2;cb.Position(3)=cb.Position(3)/3;
        end
        function ax = plot3D(obj)
            numPointsInPlot=100000;
            ticd=obj.timeIntervalCombined;
            t_org=ticd.getTimePointsInSec;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);

            dims={'X','Z','Y'};
            data1=table2array(obj.data(:,dims))';
            for ich=1:size(data1,1)
                data2(ich,:)=downsample(medfilt1(data1(ich,:),ticd.getSampleRate),downsamplefactor); %#ok<AGROW> 
            end
            color1=linspecer(size(data2,2));
            scatter3(data2(1,:),data2(2,:),data2(3,:),[],color1,'filled','MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2,'SizeData',5);
            zlabel(dims{3});
            ylabel(dims{2});
            xlabel(dims{1});
            ax=gca;
            ax.DataAspectRatio=[1 1 1];
            colormap(color1)
            cb=colorbar;cb.Ticks=[0 1];cb.TickLabels={'Earlier','Later'};cb.Location='northoutside';
            cb.Position(1)=cb.Position(1)+cb.Position(3)/3*2;cb.Position(3)=cb.Position(3)/3;
        end
        function newLocData = getTimeWindow(obj,timeWindow)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ticd=obj.timeIntervalCombined;
            ticdnew=ticd.getTimeIntervalForTimes(timeWindow(1),timeWindow(2));
            s1=ticd.getSampleFor(ticdnew.getStartTime);
            s2=ticd.getSampleFor(ticdnew.getEndTime);
            newLocData=LocationData(obj.X(s1:s2),obj.Y(s1:s2),obj.Z(s1:s2),ticdnew);
        end
        function obj = getDownsampled(obj,dsfactor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data1=table2array(obj.data)';
            for idim=1:size(data1,1)
                data1ds(idim,:)=downsample(medfilt1(data1(idim,:),dsfactor),dsfactor,dsfactor-1);
            end
            obj.data=array2table(data1ds',"VariableNames",obj.data.Properties.VariableNames);
            ticd=obj.timeIntervalCombined;
            obj.timeIntervalCombined=ticd.getDownsampled(dsfactor);
        end

        function [file1, folder]= saveInPlainFormat(obj,folder)
            ext1='position.points.csv';
            extt='position.time.csv';
            if exist('folder','var')
                if ~isfolder(folder)
                    folder= pwd;
                end
            else
                folder= fileparts(obj.source);
            end
            time=obj.timeIntervalCombined;
            timestr=matlab.lang.makeValidName(time.tostring);
            time.saveTable(fullfile(folder,[timestr extt]));
            file1=fullfile(folder,[timestr ext1]);
            writetable(obj.data,file1);
        end
        function obj= loadPlainFormat(obj,folder)
            ext1='position.points.csv';
            extt='position.time.csv';
            [file1, uni]=obj.getFile(folder,ext1);
            obj.source=file1;
            obj.data=readtable(obj.source);
            if isfile(folder)
                folder=fileparts(folder);
            end
            obj.timeIntervalCombined=neuro.time.TimeIntervalCombined( ...
                fullfile(folder,[uni extt]));
        end
        function [file2, uni]=getFile(~,folder,extension)
            if ~exist('folder','var')
                folder= pwd;
            end
            if isfile(folder)
                [folder1,name,ext1]=fileparts(folder);
                uni1=split([name ext1],extension);
                uni=uni1{1};
                file1=dir(fullfile(folder1,[uni,extension]));
            else
                file1=dir(fullfile(folder,['*' extension]));
                if numel(file1)>1
                    [name,folder1] = uigetfile({['*' extension],extension},'Selectone of the position files',folder);
                    file1=dir(fullfile(folder1,name));
                end
            end
            file2=fullfile(file1.folder,file1.name);
            [~,name,ext1]=fileparts(file2);
            uni1=split([name ext1],extension);
            uni=uni1{1};
        end
%         function [X,Y,Z,idx]= getPositionForTimesBoth(obj,times,speedthreshold)
%             ticd=obj.timeIntervalCombined;
%             speedTrack=obj.getSpeed;
%             thresholded=speedTrack.getAboveAbs(speedthreshold);
%             if ~exist([DataHash(times) '.mat'],'file')
%                 for itime=1:numel(times)
%                     sampleno(itime)=ticd.getSampleFor(times(itime));
%                 end
%                 save(DataHash(times),'sampleno')
%             else
%                 load(DataHash(times));
%             end
%             idx=ismember(sampleno,find(thresholded));
%             X=obj.data(1,sampleno);
%             Y=obj.data(2,sampleno);
%             Z=obj.data(3,sampleno);
%             
%         end
%         function [X,Y,Z,idx]= getLocationForTimesNeg(obj,times,speedthreshold)
%             ticd=obj.timeIntervalCombined;
%             speedTrack=obj.getSpeed;
%             thresholded=speedTrack.getBelow(speedthreshold);
%             if ~exist([DataHash(times) '.mat'],'file')
%                 for itime=1:numel(times)
%                     sampleno(itime)=ticd.getSampleFor(times(itime));
%                 end
%                 save(DataHash(times),'sampleno')
%             else
%                 load(DataHash(times));
%             end
%             idx=ismember(sampleno,find(thresholded));
%             X=obj.X(sampleno);
%             Y=obj.Y(sampleno);
%             Z=obj.Z(sampleno);
%             
%         end
%         function [X,Y,Z,idx]= getLocationForTimesPos(obj,times,speedthreshold)
%             ticd=obj.timeIntervalCombined;
%             speedTrack=obj.getSpeed;
%             thresholded=speedTrack.getAbove(speedthreshold);
%             if ~exist([DataHash(times) '.mat'],'file')
%                 for itime=1:numel(times)
%                     sampleno(itime)=ticd.getSampleFor(times(itime));
%                 end
%                 save(DataHash(times),'sampleno')
%             else
%                 load(DataHash(times));
%             end
%             idx=ismember(sampleno,find(thresholded));
%             X=obj.X(sampleno);
%             Y=obj.Y(sampleno);
%             Z=obj.Z(sampleno);
%             
%         end
%         function [spkArr]= getSpikeArray(obj,times)
%             ticd=obj.timeIntervalCombined;
%             spkArr=zeros(size(obj.X));
%             for itime=1:numel(times)
%                 sampleno=ticd.getSampleFor(times(itime));
%                 spkArr(sampleno)=spkArr(sampleno)+1;
%             end
%             
%         end
%         function []=plotSpikes(obj, spikeUnits)
%             figure
%             obj.plot;hold on
%             colors=linspecer(numel(spikeUnits),'qualitative');
%             ticd=obj.timeIntervalCombined;
%             ts=minutes(seconds(ticd.getTimePointsInSec));
%             for iunit=1:numel(spikeUnits)
%                 su=spikeUnits(iunit);
%                 times=su.getAbsoluteSpikeTimes;
%                 for itime=1:numel(times)
%                     color=colors(iunit,:);
%                     sampleno=ticd.getSampleFor(times(itime));
%                     t=ts(sampleno);
%                     X=obj.X(sampleno);
%                     Y=obj.Y(sampleno);
%                     Z=obj.Z(sampleno);
%                     p1=plot(t,Z,'Marker','.',...
%                         'MarkerEdgeColor',color,...
%                         'MarkerFaceColor',color,...
%                         'MarkerSize',10);hold on;
%                     %                     p1=plot(t,X);hold on;
%                     %                     p1=plot(t,Y);hold on;
%                     legend off;
%                 end
%             end
%             
%         end
        
    end
end

