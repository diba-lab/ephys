classdef PlaceFieldMapCollection
    %PLACEFIELDMAPCOLLECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PlaceFieldMaps
    end
    
    methods
        function obj = PlaceFieldMapCollection(placeFieldMaps)
            %PLACEFIELDMAPCOLLECTION Construct an instance of this class
            %   Detailed explanation goes here
            obj.PlaceFieldMaps=neuro.placeField.PlaceFieldMap.empty(0);
            if nargin>0 
                for ipf=1:numel(placeFieldMaps)
                    pf=placeFieldMaps(ipf);
                    obj=obj.add(pf);
                end
            else 

            end
        end   
        function obj = add(obj,placeField)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.PlaceFieldMaps(numel(obj.PlaceFieldMaps)+1)=placeField;
        end       
        function mat = getMatrix(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for ipf= 1:numel(obj.PlaceFieldMaps)
                pfm=obj.PlaceFieldMaps(ipf);
                mat(ipf,:)=pfm.MapSmooth;
            end
        end
        function X = getXaxis(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pfm=obj.PlaceFieldMaps(1);
            X=[min(pfm.PositionData.data.X) max(pfm.PositionData.data.X)];
        end
        function ax = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mat=obj.getMatrix;
            matz=zscore(mat,0,2);
            t=tiledlayout(3,3);nexttile(1,[3 1]);
            x=obj.getXaxis;y=1:numel(obj.PlaceFieldMaps);
            imagesc(x,y,matz,ButtonDownFcn=@(src,evt)tried(src,evt,obj,t));
            xlabel('Position (cm)');ylabel('Unit #')
            ax=gca;
        end
        function obj = sortByPeakLocalMaxima(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for ipf=1:numel(obj.PlaceFieldMaps) 
                pf=obj.PlaceFieldMaps(ipf);
                peak=pf.getPeak;
                peak.UnitNo=ones(height(peak),1)*ipf;
                if exist("peaks","var")
                    peaks=[peaks;peak(1,:)];
                else
                    peaks=peak(1,:);
                end
            end
            peaks = movevars(peaks, "UnitNo", "Before", "FiringRate");
            [~, ind]=sortrows(peaks,"Position","ascend");
            obj.PlaceFieldMaps=obj.PlaceFieldMaps(ind);
        end
        function obj = sortByPeak(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for ipf=1:numel(obj.PlaceFieldMaps) 
                pf=obj.PlaceFieldMaps(ipf);
                peak=pf.getPeak;
                peak.UnitNo=ones(height(peak),1)*ipf;
                if exist("peaks","var")
                    peaks=[peaks;peak(1,:)];
                else
                    peaks=peak(1,:);
                end
            end
            peaks = movevars(peaks, "UnitNo", "Before", "FiringRate");
            [~, ind]=sortrows(peaks,"Position","ascend");
            obj.PlaceFieldMaps=obj.PlaceFieldMaps(ind);
        end
    end
end