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
                obj.SpikePositions=spikePositions;
                obj.TimeBinSec=occupancyMap.TimeBinSec;
                obj.SpatialBinSizeCm=occupancyMap.SpatialBinSizeCm;
                obj.Smooth=occupancyMap.Smooth;
                obj.Units=occupancyMap.Units;
                obj.PositionData=occupancyMap.PositionData;
                obj.OccupancyMap=occupancyMap.MapSmooth;
                obj=obj.calculate;
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
        function obj = calculate(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj= calculate@neuro.placeField.OccupancyMap(obj);
            spikePositions=obj.SpikePositions;
            pd=obj.PositionData.data;
            PosAll=[pd.X pd.Z];
            PosSpk=[spikePositions.X spikePositions.Z];
            Pos = (PosSpk - min(PosAll)) ./ ( max(PosAll) - min(PosAll) );
            nGrid(1)=round((max(pd.X)-min(pd.X))/obj.SpatialBinSizeCm);
            nGrid(2)=round((max(pd.Z)-min(pd.Z))/obj.SpatialBinSizeCm);
            % integrized Pos (in the range 1...nGrid
            iPos = 1+floor(nGrid.*Pos/(1+eps));
            iPos(isnan(iPos(:,1)),:)=[];
            % make unsmoothed arrays
            obj.MapOriginal = full(sparse(iPos(:,2), iPos(:,1), 1, ...
                nGrid(2), nGrid(1)));
            % do the smoothing
            obj.MapSmooth=imgaussfilt(obj.MapOriginal,obj.Smooth);
        end
        function pfm = getPlaceFieldMap(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pfm=neuro.placeField.PlaceFieldMap(obj);
        end
    end
end

