classdef PositionDataManifold < optiTrack.PositionData
    %POSITIONDATAMANIFOLD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        manifold
        datamapped
        config
    end
    
    methods
        function obj = PositionDataManifold(positionData,manifold)
            %POSITIONDATAMANIFOLD Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@optiTrack.PositionData(positionData);
            data1=table2array(obj.data)';
            data2=manifold.map(data1);
            obj.datamapped=array2table(data2,"VariableNames",{'X','Z'});
            obj.manifold=manifold;
        end
        
        function [] = plotManifold(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.manifold.plotGraph
        end
        function outputArg = plotMapped(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            numPointsInPlot=200000;
            ticd=obj.timeIntervalCombined;
            t_org=ticd.getTimePointsInSec;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);
            dims=obj.datamapped.Properties.VariableNames;
            if numel(dims)>2
                dims=dims(1:3);
            end
            data1=table2array(obj.datamapped(:,dims))';
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
        function [file1, folder]= saveInPlainFormat(obj,folder)
            ext2='position.points.mapped.csv';
            if exist('folder','var')
                [file1, folder]= saveInPlainFormat@optiTrack.PositionData(obj,folder);
            else
                [file1, folder]= saveInPlainFormat@optiTrack.PositionData(obj);
            end
            time=obj.timeIntervalCombined;
            timestr=matlab.lang.makeValidName(time.tostring);
            file2=fullfile(folder,[timestr ext2]);
            writetable(obj.datamapped,file2);
        end
        function obj = loadPlainFormat(obj,folder)
            ext1='position.points.csv';
            ext2='position.points.mapped.csv';
            [file2 uni]=obj.getFile(folder,ext2);
            if exist('folder','var')
                file1=fullfile(folder,[uni ext1]);
                obj= loadPlainFormat@optiTrack.PositionData(obj,file1);
            else
                obj= loadPlainFormat@optiTrack.PositionData(obj);
            end
            obj.datamapped=readtable(file2);
        end

    end
end

