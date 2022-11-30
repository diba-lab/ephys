classdef PositionData < neuro.basic.ChannelTimeData & matlab.mixin.indexing.RedefinesParen
    %POSITIONDATA Summary of this class goes here
    %   Detailed explanation goes here

    properties
        units
    end

    methods
        function obj = PositionData(X,Y,Z,time)
            %LOCATIONDATA Construct an instance of this class
            %   ticd should be in TimeIntervalCombined foormat
            if nargin>0
                if isa(X,'optiTrack.PositionData')
                    obj.data=X.data;
                    obj.time=X.timeIntervalCombined;
                    obj.units=X.units;
                elseif numel(X)==numel(Y)&&numel(Z)==numel(Y)&&...
                        numel(X)==time.getNumberOfPoints
                    data(1,:)=X;
                    data(2,:)=Y;
                    data(3,:)=Z;
                    obj.data=array2table(data','VariableNames',{'X','Y','Z'});
                    obj.time = time;
                    obj.units='cm';
                else
                    error('Sizes of XYZ or time are not equal.')
                end
            end
        end
        function pd=getWindow(obj,plsd)
            ticd=obj.time;
            pd=obj;
            window=ticd.getTimeIntervalForTimes(plsd);
            pd.time=window;
            samples=ticd.getSampleForClosest(plsd);
            idx=samples(1):samples(2);
            pd.data=obj.data(idx,:);
        end
        function pd=plus(obj,pd)
            %             ticd=obj.time;
            %             pd=obj;
            %             window=ticd.getTimeIntervalForTimes(plsd);
            %             pd.timeIntervalCombined=window;
            %             samples=ticd.getSampleForClosest(plsd);
            %             idx=samples(1):samples(2);
            %             pd.data=obj.data(idx,:);
        end
        function data=getData(obj)
            data=obj.data;
        end
        function obj=setData(obj,data)
            obj.data=data;
        end
        function mat=flatten2(obj)
            mat=obj.data(1:2,:);
        end
        function mat=flatten3(obj)
            mat=obj.data(1:3,:);
        end

        function pdman=getManifold(obj)
            time=obj.time; %#ok<*PROPLC>
            timestr=matlab.lang.makeValidName(time.tostring);
            file1=java.io.File(obj.source);
            manifoldFile=fullfile(char(file1.getParent),[ ...
                'position.PositionDataManifold' timestr '.mat'...
                ]);
            
            if ~exist(manifoldFile,'file')
                try close(123);catch,end; figure(123);
                f=gcf;f.Position(3:4)=[1500 500];
                c.numberOfPoints=200;
                c.neighbors=7;
                obj1=obj.getDownsampled(obj.time.getSampleRate);
                spd=obj1.getSpeed.Values;
                [~,I]=sort(spd,'descend',MissingPlacement='last');

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
                pdman=position.PositionDataManifold(obj,manifold);
                pdman.config=c;
                subplot(2,2,3);
                pdman.plot2D
                ff=logistics.FigureFactory.instance(char(file1.getParent));
                ff.save(['position-PositionDataManifold-' timestr]);
                save(manifoldFile,"pdman",'-mat');
            else
                s=load(manifoldFile);
                pdman=s.pdman;
                if isempty(pdman.units), pdman.units='cm';end
            end
        end

        function [vel]= getSpeed(obj,smoothingWindowInSec)
            data1=table2array(obj.getData)';
            dt=diff(obj.time.getTimePointsInSec);
            for idim=1:size(data1,1)
                speed2(idim,:)=diff(data1(idim,:)).^2;
            end
            v=sqrt(sum(speed2,1))./dt;
            if exist('smoothingWindowInSec','var')
                v=smoothdata(v,'gaussian',obj.time.getSampleRate* ...
                    smoothingWindowInSec);
            end
            vel=neuro.basic.Channel('Velocity',[0 v],obj.time);
        end
        function [om]= getOccupancyMap(obj,xedges,zedges)
            if nargin==1
                om=neuro.placeField.OccupancyMap(obj,obj.time.getSampleRate);
            else
                om=neuro.placeField.OccupancyMap(obj, ...
                    obj.time.getSampleRate,xedges,zedges);
            end
            om.Units=obj.units;
        end
        function ax = plot(obj)
            numPointsInPlot=100000;
            ticd=obj.time;
            t_org=ticd.getTimePointsInSec-seconds(ticd.getZeitgeberTime- ...
                ticd.getStartTime);
            downsamplefactor=round(numel(t_org)/numPointsInPlot);
            data1=table2array(obj.getData)';
            for ich=1:size(data1,1)
                data2(ich,:)=downsample(medfilt1(data1(ich,:), ...
                    ticd.getSampleRate),downsamplefactor); %#ok<AGROW>
            end
            t=hours(seconds(downsample(t_org,downsamplefactor)));
            vel=obj.getSpeed.getMeanFiltered(1);
            vel1=downsample(vel.Values,downsamplefactor);
            vel1(isnan(vel1)|vel1==0)=0.001;
            scatter(t,data2,abs(vel1)*5000,'filled','MarkerFaceAlpha',.2, ...
                'MarkerEdgeAlpha',.2,'SizeData',5);
            legend(obj.getData.Properties.VariableNames);
            xlabel('ZT (Hrs)');
            ylabel(['Location (',obj.units,')']);
            ax=gca;
        end
        function ax = plot2D(obj, numPointsInPlot)
            if ~exist('numPointsInPlot','var')
                numPointsInPlot=10000;
            end
            ticd=obj.time;
            t_org=ticd.getTimePointsInSecZT;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);

            dims={'X','Z'};
            data0=obj.getData;
            data1=table2array(data0(:,dims))';
            for ich=1:size(data1,1)
                data2(ich,:)=downsample(medfilt1(data1(ich,:), ...
                    ticd.getSampleRate),downsamplefactor); %#ok<AGROW>
            end
            color1=linspecer(size(data2,2));
            scatter(data2(1,:),data2(2,:),[],color1, ...
                'filled','MarkerFaceAlpha',.2, ...
                'MarkerEdgeAlpha',.2,'SizeData',5);
            ylabel([dims{2} ' ' obj.units]);
            xlabel([dims{1} ' ' obj.units]);
            ax=gca;
            ax.DataAspectRatio=[1 1 1];
            colormap(color1)
            
%             cb=colorbar;cb.Ticks=[0 1];cb.TickLabels={'Earlier','Later'};
%             cb.Location='eastoutside';
        end
        function ax = plot3Dtime(obj, numPointsInPlot)
            if ~exist('numPointsInPlot','var')
                numPointsInPlot=10000;
            end
            ticd=obj.time;
            t_org=ticd.getTimePointsInSecZT;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);

            dims={'X','Z','Y'};
            data0=obj.getData;
            data1=table2array(data0(:,dims))';
            for ich=1:size(data1,1)
                data2(ich,:)=downsample(medfilt1(data1(ich,:), ...
                    ticd.getSampleRate),downsamplefactor); %#ok<AGROW>
            end
            data2(3,:)=data2(3,:)+linspace(1,t_org(end)-t_org(2),size(data2,2)); % add time
            color1=linspecer(size(data2,2));
            scatter3(data2(1,:),data2(2,:),data2(3,:),[],color1, ...
                'filled','MarkerFaceAlpha',.2, ...
                'MarkerEdgeAlpha',.2,'SizeData',5);
            zlabel('Time (s)');
            ylabel(dims{2});
            xlabel(dims{1});
            ax=gca;
            ax.DataAspectRatio=[1 1 4];
            colormap(color1)
%             cb=colorbar;cb.Ticks=[0 1];cb.TickLabels={'Earlier','Later'};
%             cb.Location='northoutside';
%             cb.Position(1)=cb.Position(1)+cb.Position(3)/3*2;
%             cb.Position(3)=cb.Position(3)/3;
        end
        function ax = plot3DtimeContinuous(obj, numPointsInPlot)
            if ~exist('numPointsInPlot','var')
                numPointsInPlot=10000;
            end
            ticd=obj.time;
            t_org=ticd.getTimePointsInSecZT;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);

            dims={'X','Z','Y'};
            data0=obj.getData;
            data1=table2array(data0(:,dims))';
            for ich=1:size(data1,1)
                data2(ich,:)=downsample(medfilt1(data1(ich,:), ...
                    ticd.getSampleRate),downsamplefactor); %#ok<AGROW>
            end
            data2(3,:)=data2(3,:)+linspace(1,t_org(end)-t_org(2),size(data2,2)); % add time
            plot3(data2(1,:),data2(2,:),data2(3,:),LineWidth=1);
            zlabel('Time (s)');
            ylabel(dims{2});
            xlabel(dims{1});
            ax=gca;
            ax.DataAspectRatio=[1 1 4];
        end
        function ax = plot3D(obj, numPointsInPlot)
            if ~exist('numPointsInPlot','var')
                numPointsInPlot=10000;
            end
            ticd=obj.time;
            t_org=ticd.getTimePointsInSecZT;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);

            dims={'X','Z','Y'};
            data0=obj.getData;
            data1=table2array(data0(:,dims))';
            for ich=1:size(data1,1)
                data2(ich,:)=downsample(medfilt1(data1(ich,:), ...
                    ticd.getSampleRate),downsamplefactor); %#ok<AGROW>
            end
            plot3(data2(1,:),data2(2,:),data2(3,:));
            zlabel(dims{3});
            ylabel(dims{2});
            xlabel(dims{1});
        end
        function [] = plot3DMark(obj,mark)

            ticd=obj.time;
            t_org=ticd.getTimePointsInSec;

            dims={'X','Z','Y'};
            data0=obj.getData;
            data1=table2array(data0(:,dims))';
            data1(3,:)=data1(3,:)+linspace(1,t_org(end)-t_org(2),size(data1,2)); % add time

            data2=data1(:,mark);
            s=scatter3(data2(1,:),data2(2,:),data2(3,:),[],'filled', ...
                'MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.5,'SizeData',30);
            s.MarkerFaceColor="k";
            ylabel([dims{2} ' ' obj.units]);
            xlabel([dims{1} ' ' obj.units]);

        end
        function [] = plot2DMark(obj,mark)
            dims={'X','Z','Y'};
            data0=obj.getData;
            data1=table2array(data0(:,dims))';

            data2=data1(:,mark);
            s=scatter(data2(1,:),data2(2,:),[],'filled', ...
                'MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.5,'SizeData',5);
            s.MarkerFaceColor="k";
            ylabel([dims{2} ' ' obj.units]);
            xlabel([dims{1} ' ' obj.units]);

        end
        function obj = getTimeWindow(obj,timeWindow)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ticd=obj.time;
            ticdnew=ticd.getTimeIntervalForTimes(timeWindow);
            s1=ticd.getSampleFor(ticdnew.getStartTime);
            s2=ticd.getSampleFor(ticdnew.getEndTime);
            obj.time=ticdnew;
            obj.data=obj.data(s1:s2,:);
        end
        function obj = getDownsampled(obj,dsfactor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data1=table2array(obj.data)';
            for idim=1:size(data1,1)
                data1ds(idim,:)=downsample(medfilt1(data1(idim,:),dsfactor),dsfactor,dsfactor-1);
            end
            obj.data=array2table(data1ds',"VariableNames",obj.data.Properties.VariableNames);
            ticd=obj.time;
            obj.time=ticd.getDownsampled(dsfactor);
        end
        function [data1,sample] = getPositionForTimes(obj,times)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            time=obj.time;
            sample=time.getSampleForClosest(times);
            data1=obj.data(sample,:);
        end

        function [obj, folder]= saveInPlainFormat(obj,folder,ext1)
            if ~exist('ext1','var')
                ext1='position.points.csv';
            end
            extt='position.time.csv';
            if exist('folder','var')
                if ~isfolder(folder)
                    folder= pwd;
                end
            else
                folder= fileparts(obj.source);
            end
            time=obj.time; %#ok<*PROPLC>
            timestr=matlab.lang.makeValidName(time.tostring);
            time.saveTable(fullfile(folder,[timestr extt]));
            file1=fullfile(folder,[timestr ext1]);
            writetable(obj.data,file1);
            folder=string(py.os.path.realpath(py.os.path.expanduser(folder)));
%             obj=obj.loadPlainFormat(folder);
        end
        function obj= loadPlainFormat(obj,folder)
            ext1='position.points.csv';
            extt='position.time.csv';
            [file1, uni]=obj.getFile(folder,ext1);
            obj.source=file1;
            obj.data=readtable(obj.source);
            folder=fileparts(file1);
            obj.time=neuro.time.TimeIntervalCombined( ...
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
    end
    methods (Access=protected)
        function obj = parenReference(obj, indexOp)
            idx=indexOp.Indices{:};
            data=table2array(obj.data);
            data(~idx,:) =nan;
            obj.data=array2table(data,VariableNames=obj.data.Properties.VariableNames);
        end

        function obj = parenAssign(obj,indexOp,varargin)
            % Ensure object instance is the first argument of call.
            if isempty(obj)
                obj = varargin{1};
            end
            if isscalar(indexOp)
                assert(nargin==3);
                rhs = varargin{1};
                obj.ContainedArray.(indexOp) = rhs.ContainedArray;
                return;
            end
            [obj.(indexOp(2:end))] = varargin{:};
        end

        function n = parenListLength(obj,indexOp,ctx)
            if numel(indexOp) <= 2
                n = 1;
                return;
            end
            containedObj = obj.(indexOp(1:2));
            n = listLength(containedObj,indexOp(3:end),ctx);
        end

        function obj = parenDelete(obj,indexOp)
            obj.ContainedArray.(indexOp) = [];
        end
    end
    methods
        function out = cat(dim,varargin)
            numCatArrays = nargin-1;
            newArgs = cell(numCatArrays,1);
            for ix = 1:numCatArrays
                if isa(varargin{ix},'ArrayWithLabel')
                    newArgs{ix} = varargin{ix}.ContainedArray;
                else
                    newArgs{ix} = varargin{ix};
                end
            end
            out = ArrayWithLabel(cat(dim,newArgs{:}));
        end

        function varargout = size(obj,varargin)
            [varargout{1:nargout}] = size(obj.ContainedArray,varargin{:});
        end
    end
end

