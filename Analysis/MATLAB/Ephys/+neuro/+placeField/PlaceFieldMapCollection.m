classdef PlaceFieldMapCollection
    %PLACEFIELDMAPCOLLECTION Summary of this class goes here
    %   Detailed explanation goes here

    properties
        PlaceFieldMaps
        CacheManager
    end

    methods
        function obj = PlaceFieldMapCollection(cacheManagerFile,placeFieldMaps)
            %PLACEFIELDMAPCOLLECTION Construct an instance of this class
            %   Detailed explanation goes here
            if ~isa(cacheManagerFile,'cache.Manager')
                obj.CacheManager=cache.Manager.instance(cacheManagerFile);
            else
                obj.CacheManager=cacheManagerFile;
            end
            obj.PlaceFieldMaps=neuro.placeField.PlaceFieldMapMeasures.empty(0);
            if nargin>1
                for ipf=1:numel(placeFieldMaps)
                    pf=placeFieldMaps(ipf);
                    obj=obj.add(pf);
                end
            else

            end
        end
        function obj = add(obj,placeField,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isa(placeField,'neuro.placeField.PlaceFieldMap')
                obj.PlaceFieldMaps(numel(obj.PlaceFieldMaps)+1)=placeField;
            elseif isa(placeField,'neuro.placeField.PlaceFieldMapCollection')
                for ip=1:numel(placeField.PlaceFieldMaps)
                    obj=obj.add(placeField.PlaceFieldMaps(ip));
                end
            end
        end
        function mat = getMatrix(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for ipf= 1:numel(obj.PlaceFieldMaps)
                pfm=obj.PlaceFieldMaps(ipf);
                try 
                    mat(ipf,:)=pfm.MapSmooth;
                catch me
                    matsize=size(mat,2);
                    if numel(pfm.MapSmooth)>matsize
                        mat(ipf,:)=pfm.MapSmooth(1:matsize);
                    else
                        ad1=nan([1 abs(matsize-numel(pfm.MapSmooth))]);
                        mat(ipf,:)=[pfm.MapSmooth ad1];
                    end
                end
            end
        end
        function X = getXaxis(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pfm=obj.PlaceFieldMaps(1);
            X=[min(pfm.PositionData.data.X) max(pfm.PositionData.data.X)];
        end
        function ax = plot(obj,pp)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mat=obj.getMatrix;
            matz=normalize(mat,2,"range");
            t=tiledlayout(6,3);nexttile(1,[6 1]);
            x=obj.getXaxis;y=1:numel(obj.PlaceFieldMaps);
            imagesc(x,y,matz,ButtonDownFcn=@(src,evt)updatePlaceFieldPlotsUni( ...
                src,evt,obj,pp,t));
            xlabel('Position (cm)');ylabel('Unit #')
            ax=gca;
            ax.YTick=y;
            ax.YTickLabel=num2str(obj.getUnitInfoTable.id);
            tbl=obj.getPlaceFieldInfoTable;
            info=normalize([tbl.Information],1,"range");
            sta=normalize([tbl.Stability.gini],2,"range");
            x1=ones(size(y))*x(1);hold on;
            scatter(x1,y,200,info,"filled",AlphaData=.2,Marker="square");
            x2=ones(size(y))*x(2);hold on;
            scatter(x2,y,200,sta,"filled",AlphaData=.8,Marker="square");
        end
        function [obj, ind]= sortByPeakLocalMaxima(obj)
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
        function tbl = getUnitInfoTable(obj)
            for ipf=1:numel(obj.PlaceFieldMaps)
                pf=obj.PlaceFieldMaps(ipf);
                su=pf.SpikeUnitTracked;
                if exist('tbl','var')
                    tbl=[tbl; su.getInfoTable];
                else
                    tbl=su.getInfoTable;
                end
            end
        end
        function tbl = getPlaceFieldInfoTable(obj)
            stabilityNums=3;
            vals=[2 6];
            for ipf=1:numel(obj.PlaceFieldMaps)
                pf=obj.PlaceFieldMaps(ipf);
                s.Information=pf.Information;
                s.Stability=pf.Stability;
%                 s.Stability.gini=1-...
%                     sum(abs(s.Stability.cum-s.Stability.basecum))/...
%                     sum(s.Stability.basecum);
                s.PlaceFields={pf.PlaceFields};
                cor1=pf.calculateStabilityCorr(stabilityNums);
                R=cor1.R(vals);
                p1=cor1.P(vals);
                R(isnan(R))=0;
                s.Stability.CorrR1=R(1);
                s.Stability.CorrR2=R(2);
                peak=pf.getPeak;
                tbl1=struct2table(s,'AsArray',true);
                tbl2=[tbl1 peak];
                if exist("tbl","var")
                    tbl=[tbl; tbl2];
                else
                    tbl=tbl2;
                end
            end
        end
        function obj = getUnits(obj,idx)
            obj.PlaceFieldMaps=obj.PlaceFieldMaps(idx);
        end
    end
end