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
        XEdges
        ZEdges
    end
    
    methods
        function obj = OccupancyMap(positionData,srate,xedges,zedges)
            %OCCUPANCYMAP Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                obj.PositionData = positionData;
                obj.TimeBinSec=1/srate;
                obj.Smooth=5;
                obj.SpatialBinSizeCm=1;
                if nargin>2
                    obj=obj.calculate(xedges,zedges);
                else
                    obj=obj.calculate();
                end
            end
        end
        function [] = plot(obj)
            ms=obj.MapSmooth;
            ms(ms<eps)=0;
            alpha1=log(ms);
            x=obj.getXLim;
            y=obj.getZLim;
            imagesc(x,y,obj.MapOriginal,AlphaDataMapping="scaled",AlphaData=alpha1);    
        end
        function [] = plotSmooth(obj)
            ms=obj.MapSmooth;
            ms(ms<eps)=0;
            alpha1=log(ms);
            x=obj.getXLim;
            y=obj.getZLim;
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
        
        function obj = calculate(obj,xedges,zedges)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pd=obj.PositionData.data;
            Pos1=[pd.X pd.Z];
            if nargin==1
                nGrid(1)=round((max(pd.X)-min(pd.X))/obj.SpatialBinSizeCm);
                nGrid(2)=round((max(pd.Z)-min(pd.Z))/obj.SpatialBinSizeCm);
                [obj.MapOriginal,Xedges,Zedges]=histcounts2( ...
                    Pos1(:,1),Pos1(:,2),nGrid);
            else
                [obj.MapOriginal,Xedges,Zedges]=histcounts2( ...
                    Pos1(:,1),Pos1(:,2),xedges,zedges);
            end
            obj.MapOriginal=obj.MapOriginal';
            % do the smoothing
            obj.MapSmooth=imgaussfilt(obj.MapOriginal,obj.Smooth);
%             figure; tiledlayout('flow'); 
%             nexttile; imagesc(obj.MapOriginal);
%             nexttile; imagesc(obj.MapSmooth);

            obj.XEdges=Xedges;
            obj.ZEdges=Zedges;
        end
        function frm = plus(obj,spikeTimes)
            frm=neuro.placeField.FireRateMap(obj,spikeTimes);
        end
        function xl = getXLim(obj)
            xl=[min(obj.XEdges) max(obj.XEdges)];
        end
        function yl = getZLim(obj)
            yl=[min(obj.ZEdges) max(obj.ZEdges)];
        end
    end
end

