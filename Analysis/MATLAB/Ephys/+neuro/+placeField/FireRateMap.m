classdef FireRateMap < neuro.placeField.OccupancyMap
    %FIRERATEMAP Summary of this class goes here
    %   Detailed explanation goes here

    properties
        SpikePositions
        OccupancyMap
        SpikeUnitTracked
    end

    methods
        function obj = FireRateMap(occupancyMap,spikePositions)
            %FIRERATEMAP Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                fnames=fieldnames(occupancyMap);
                for ifn=1:numel(fnames)
                    obj.(fnames{ifn})=occupancyMap.(fnames{ifn});
                end
                obj.SpikePositions=spikePositions;
                obj.PositionData=occupancyMap.PositionData;
                obj.OccupancyMap=occupancyMap.MapSmooth;
                if ~(isempty(obj.XEdges)||isempty(obj.ZEdges))
                    obj=obj.calculate(obj.XEdges,obj.ZEdges);
                else
                    obj=obj.calculate;
                end
            end
        end
        function [] = plot(obj)
            ms=obj.OccupancyMap;
            ms(ms<eps)=0;
            alpha1=log(ms);
            x=[min(obj.PositionData.data.X) max(obj.PositionData.data.X)];
            y=[min(obj.PositionData.data.Z) max(obj.PositionData.data.Z)];
            imagesc(x,y,obj.MapOriginal,AlphaDataMapping="scaled",AlphaData=alpha1);
        end
        function [] = plotSmooth(obj)
            ms=obj.OccupancyMap;
            ms(ms<eps)=0;
            alpha1=log(ms);
            x=[min(obj.PositionData.data.X) max(obj.PositionData.data.X)];
            y=[min(obj.PositionData.data.Z) max(obj.PositionData.data.Z)];
            imagesc(x,y,obj.MapSmooth,AlphaDataMapping="scaled",AlphaData=alpha1);
        end
        function obj = calculate(obj,xedges,zedges)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj= calculate@neuro.placeField.OccupancyMap(obj);
            spikePositions=obj.SpikePositions;
            pd=obj.PositionData.data;
            PosSpk=[spikePositions.X spikePositions.Z];
            if nargin==1
                nGrid(1)=round((max(pd.X)-min(pd.X))/obj.SpatialBinSizeCm);
                nGrid(2)=round((max(pd.Z)-min(pd.Z))/obj.SpatialBinSizeCm);
                [obj.MapOriginal]=histcounts2( ...
                    PosSpk(:,1),PosSpk(:,2),nGrid);
            else
                [obj.MapOriginal]=histcounts2( ...
                    PosSpk(:,1),PosSpk(:,2),xedges,zedges);
            end
            obj.MapOriginal=obj.MapOriginal'./obj.TimeBinSec;

            % do the smoothing
            obj.MapSmooth=imgaussfilt(obj.MapOriginal,obj.Smooth);
        end
        function pfm = getPlaceFieldMap(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pfm1=neuro.placeField.PlaceFieldMap(obj);
            pfm=pfm1.getPlaceFieldMapMeasures;
        end
    end
end

