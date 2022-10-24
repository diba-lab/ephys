classdef PlaceFieldMap<neuro.placeField.FireRateMap
    %PLACEFIELDMAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimeTreshold
        FireRateMap
    end

    methods
        function obj = PlaceFieldMap(fireRateMap)
            %PLACEFIELDMAP Construct an instance of this class
            %   Detailed explanation goes here
            obj.TimeTreshold=1*fireRateMap.TimeBinSec;
            obj.SpikePositions=fireRateMap.SpikePositions;
            obj.TimeBinSec=fireRateMap.TimeBinSec;
            obj.SpatialBinSizeCm=fireRateMap.SpatialBinSizeCm;
            obj.Smooth=fireRateMap.Smooth;
            obj.Units=fireRateMap.Units;
            obj.PositionData=fireRateMap.PositionData;
            obj.OccupancyMap=fireRateMap.OccupancyMap;
            obj.FireRateMap=fireRateMap.MapSmooth;

            obj.FireRateMap(obj.OccupancyMap<obj.TimeTreshold)=eps;
            obj.MapSmooth=obj.FireRateMap./(obj.OccupancyMap+eps);
            obj.MapSmooth=imgaussfilt(obj.MapSmooth,obj.Smooth);
        end
        function [] = plot(obj)
            ms=obj.OccupancyMap;
            ms(ms<eps)=0;
            alpha1=log(ms);
            x=[min(obj.PositionData.X) max(obj.PositionData.X)];
            y=[min(obj.PositionData.Z) max(obj.PositionData.Z)];
            imagesc(x,y,obj.MapOriginal,AlphaDataMapping="scaled",AlphaData=alpha1);
            xlabel(['X ' obj.Units])
            ylabel(['Z ' obj.Units])
        end
        function [] = plotSmooth(obj)
            ms=obj.OccupancyMap;
            ms(ms<eps)=0;
            alpha1=log(ms);
            x=[min(obj.PositionData.X) max(obj.PositionData.X)];
            y=[min(obj.PositionData.Z) max(obj.PositionData.Z)];
            imagesc(x,y,obj.MapSmooth,AlphaDataMapping="scaled",AlphaData=alpha1);
            %             ax=gca;ax.CLim=[.05 .2];
            xlabel(['X ' obj.Units])
            ylabel(['Z ' obj.Units])
        end
        function [] = getPeak(obj)
            ms=obj.OccupancyMap;
            ms(ms<eps)=0;
            alpha1=log(ms);
            x=[min(obj.PositionData.X) max(obj.PositionData.X)];
            y=[min(obj.PositionData.Z) max(obj.PositionData.Z)];
            imagesc(x,y,obj.MapSmooth,AlphaDataMapping="scaled",AlphaData=alpha1);
            %             ax=gca;ax.CLim=[.05 .2];
            xlabel(['X ' obj.Units])
            ylabel(['Z ' obj.Units])
        end
    end
end

