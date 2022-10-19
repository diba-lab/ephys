classdef OccupancyMap
    %OCCUPANCYMAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimeBinSec
        SpatialBinSizeCm
        Smooth
        PositionData
        MapOriginal
        MapSmooth
        Units
    end
    
    methods
        function obj = OccupancyMap(positionData,srate)
            %OCCUPANCYMAP Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                obj.PositionData = positionData;
                obj.TimeBinSec=1/srate;
                obj.Smooth=5;
                obj.SpatialBinSizeCm=1;
                obj=obj.calculate;
            end
        end
        function [] = plot(obj)
            ms=obj.MapSmooth;
            ms(ms<eps)=0;
            alpha1=log(ms);
            x=[min(obj.PositionData.X) max(obj.PositionData.X)];
            y=[min(obj.PositionData.Z) max(obj.PositionData.Z)];
            imagesc(x,y,obj.MapOriginal,AlphaDataMapping="scaled",AlphaData=alpha1);    
        end
        function [] = plotSmooth(obj)
            ms=obj.MapSmooth;
            ms(ms<eps)=0;
            alpha1=log(ms);
            x=[min(obj.PositionData.X) max(obj.PositionData.X)];
            y=[min(obj.PositionData.Z) max(obj.PositionData.Z)];
            imagesc(x,y,obj.MapSmooth,AlphaDataMapping="scaled",AlphaData=alpha1);    
        end
        function obj = setTimeBinSec(obj,val)
            obj.TimeBinSec=val;
            obj=obj.calculate;
        end
        function obj = setSmooth(obj,val)
            obj.Smooth=val;
            obj=obj.calculate;
        end
        function obj = setSpatialBinSizeCm(obj,val)
            obj.SpatialBinSizeCm=val;
            obj=obj.calculate;
        end
        
        function obj = calculate(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pd=obj.PositionData;
            Pos1=[pd.X pd.Z];
            Pos = (Pos1 - min(Pos1)) ./ ( max(Pos1) - min(Pos1) );
            nGrid(1)=round((max(pd.X)-min(pd.X))/obj.SpatialBinSizeCm);
            nGrid(2)=round((max(pd.Z)-min(pd.Z))/obj.SpatialBinSizeCm);
            % integrized Pos (in the range 1...nGrid
            iPos = 1+floor(nGrid.*Pos/(1+eps));
            iPos(isnan(iPos(:,1)),:)=[];
            % make unsmoothed arrays
            obj.MapOriginal = full(sparse(iPos(:,2), iPos(:,1), 1, ...
                nGrid(2), nGrid(1)))*obj.TimeBinSec;

            % do the smoothing
            obj.MapSmooth=imgaussfilt(obj.MapOriginal,obj.Smooth);
%             figure; tiledlayout('flow'); 
%             nexttile; imagesc(obj.MapOriginal);
%             nexttile; imagesc(obj.MapSmooth);
        end
        function frm = plus(obj,spikeTimes)
            frm=neuro.placeField.FireRateMap(obj,spikeTimes);
        end
    end
end

