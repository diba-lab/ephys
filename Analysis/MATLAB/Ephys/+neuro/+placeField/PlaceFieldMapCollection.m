classdef PlaceFieldMapCollection
    %PLACEFIELDMAPCOLLECTION Summary of this class goes here
    %   Detailed explanation goes here

    properties
        PlaceFieldMaps
        PlaceFieldMapKeys
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
        function pf1 = getPlaceField(obj,pfNo)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            try
                pf=obj.PlaceFieldMaps(pfNo);
            catch ME
                if strcmp(ME.identifier,'MATLAB:badsubscript')
                    pf=obj.getPlaceFieldWithNoPosition(pfNo);
                else
                    rethrow(ME);
                end            
            end
            for ip=1:numel(pf)
                pf1(ip)=pf(ip).getPositionReload(obj.CacheManager);
            end
        end
        function pf = getPlaceFieldWithNoPosition(obj,pfNo)
            cm=obj.CacheManager;
            cm=cm.reload();
            for ip=1:numel(pfNo)
                pf(ip)=cm.get(obj.PlaceFieldMapKeys(pfNo(ip)));
            end
        end
        function pf1 = getPlaceFieldByUnitID(obj,unitID)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for iunit=1:numel(obj.PlaceFieldMapKeys)
                pf1=obj.getPlaceFieldWithNoPosition(iunit);
                ids(iunit)=pf1.SpikeUnitTracked.Id;
            end
            idx=find(ismember(ids,unitID));

            pf1=obj.getPlaceField(idx);
        end
        function obj = add(obj, placeField, varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isa(placeField,'neuro.placeField.PlaceFieldMap')
                [obj.CacheManager,placeField1]= placeField.getPositionHeld(...
                    obj.CacheManager);
                [obj.CacheManager,key]=obj.CacheManager.hold(placeField1);
                nextnumber=numel(obj.PlaceFieldMapKeys)+1;
                obj.PlaceFieldMapKeys{nextnumber}=key;
            elseif isa(placeField,'neuro.placeField.PlaceFieldMapCollection')
                for ip=1:numel(placeField.PlaceFieldMaps)
                    obj=obj.add(placeField.getPlaceField(ip));
                end
            end
        end
        function obj = plus(obj, placeField, varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj=obj.add(placeField);
        end
        function mat = getMatrix(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for ipf= 1:numel(obj.PlaceFieldMaps)
                pfm=obj.getPlaceField(ipf);
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
            imagesc(x,y,matz,ButtonDownFcn= ...
                @(src,evt)updatePlaceFieldPlotsUni( ...
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
                pf=obj.getPlaceField(ipf);
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
            if ~isempty(obj.PlaceFieldMapKeys)
                pfs=obj.PlaceFieldMapKeys;
            else
                pfs=obj.PlaceFieldMaps;
            end
            for ipf=1:numel(pfs)
                pf=obj.getPlaceField(ipf);
                su=pf.SpikeUnitTracked;
                if exist('tbl','var')
                    tbl=[tbl; su.getInfoTable];
                else
                    tbl=su.getInfoTable;
                end
            end
        end
        function tbl = getPlaceFieldInfoTable(obj,winds)
            stabilityNums=3;
            vals=[2 6];
            if ~isempty(obj.PlaceFieldMapKeys)
                pfs=obj.PlaceFieldMapKeys;
            else
                pfs=obj.PlaceFieldMaps;
            end

            for ipf=1:numel(pfs)
                pf=obj.getPlaceField(ipf);
                s.Information=pf.Information;
                s.Stability=pf.Stability;
                s.PlaceFields={pf.PlaceFields};
                cor1=pf.calculateStabilityCorr(stabilityNums);
                R=cor1.R(vals);
                p1=cor1.P(vals);
                R(isnan(R))=0;
                s.Stability.CorrR1=R(1);
                s.Stability.CorrR2=R(2);
                for imaps=1:numel(cor1.maps)
                    amap=cor1.maps(imaps);
                    amap.PositionData=[];
                    amap.SpikeUnitTracked.PositionData=[];
                    s.Stability.maps(imaps)=amap;
                end
                cor2=pf.calculateStabilityCorrLapbased(winds);
                R2=cor2.R(vals);
                p2=cor2.P(vals);
                R2(isnan(R2))=0;
                s.Stability.Corr2R1=R2(1);
                s.Stability.Corr2R2=R2(2);
                for imaps=1:numel(cor2.maps)
                    amap2=cor2.maps(imaps);
                    amap2.PositionData=[];
                    amap2.SpikeUnitTracked.PositionData=[];
                    s.Stability.maps2(imaps)=amap2;
                end
                peak=pf.getPeak;
                pf.Parent=[];
                pf.PositionData=[];
                pf.SpikeUnitTracked.PositionData=[];
                s.Map=pf;
                tbl1=struct2table(s,'AsArray',true);
                tbl2=[tbl1 peak];
                if exist("tbl","var")
                    tbl=[tbl; tbl2];
                else
                    tbl=tbl2;
                end
            end
        end
        function pfs = getUnits(obj,idx)
            if islogical(idx)
                idxs=find(idx);
            elseif isnumeric(idx)
                idxs=idx;
            elseif isstring(idx)||ischar(idx)
                if strcmpi(idx,'all')
                    idxs=true(obj.getNumberOfUnits,1);
                end
            end
            pfs=neuro.placeField.PlaceFieldMapMeasures.empty(numel(idxs),0);
            for i=1:numel(idxs)
                loc=idxs(i);
                pfs(i)=obj.getPlaceField(loc);
            end
        end
        function num = getNumberOfUnits(obj)
            num=max(numel(obj.PlaceFieldMapKeys),numel(obj.PlaceFieldMaps));
        end
    end
end