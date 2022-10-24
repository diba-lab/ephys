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
        function obj = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mat=obj.getMatrix;
            matz=zscore(mat,0,2);
            imagesc(matz);
        end
        function obj = sortByPeak(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for ipf=1:numel(obj.PlaceFieldMaps) 

            end
            mat=obj.getMatrix;
            matz=zscore(mat,0,2);
            imagesc(matz);
        end
    end
end