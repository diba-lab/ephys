classdef PlaceFieldMapMeasures < neuro.placeField.PlaceFieldMap
    %PLACEFIELDMAPMAESURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Information
        Stability
        PlaceFields
    end
    
    methods
        function obj = PlaceFieldMapMeasures(placeFieldMap)
            %PLACEFIELDMAPMAESURES Construct an instance of this class
            %   Detailed explanation goes here
            fnames=fieldnames(placeFieldMap);
            for ifn=1:numel(fnames)
                obj.(fnames{ifn})=placeFieldMap.(fnames{ifn});
            end
            obj.Information=obj.calculateInformation;
            if min(size(obj.MapSmooth))==1
                [obj.Stability.gini,...
                    obj.Stability.cum,...
                    obj.Stability.basecum]=...
                    obj.calculateStabilityGini;
                obj.PlaceFields=obj.calculatePlaceFields;
            end
        end
        function information = calculateInformation(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mapFR=obj.MapSmooth;
            idx=obj.OccupancyMap>eps;
            posbinsFR=mapFR(idx);
            Pi=obj.OccupancyMap(idx)/sum(obj.OccupancyMap(idx));
            duration=sum(~isnan(obj.PositionData.data.X))/...
                obj.PositionData.time.getSampleRate;
            meanFiringRate=height(obj.SpikePositions)/duration;
            FRiRatio=posbinsFR/meanFiringRate;
            els=Pi.*FRiRatio.*log2(FRiRatio);
            information=sum(els,'omitnan');
        end
        function [gini, cumfiring2, basecumfire]= calculateStabilityGini(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pfs=obj.calculatePlaceFields;
            if ~isempty(pfs)
                pf=pfs(1,:);

                pfrang=round([pf.Position-pf.Width/2 pf.Position+pf.Width/2]);
                pdata= obj.PositionData;
                idx=pdata.data.X>pfrang(1)&pdata.data.X<pfrang(2);
                tp1=seconds(pdata.time.getTimePointsZT);
                tp=tp1(idx);
                tps=zeros(size(tp));
                stimes=seconds(obj.SpikeUnitTracked.getTimesZT);
                for is=1:numel(stimes)
                    [val,loc]=min(abs(stimes(is)-tp));
                    if val<1/pdata.time.getSampleRate
                        tps(loc)=tps(loc)+1;
                    end
                end
                cumfiring1=cumsum(tps);
                cumfiring2 = cumfiring1/max(cumfiring1);
                basecumfire=linspace(0,1,numel(cumfiring2));
                apb=sum(basecumfire);
                gini = 1-sum(abs(basecumfire-cumfiring2))/apb;
            else
                gini=nan;
                cumfiring2=nan;
                basecumfire=nan;
            end
        end
        function [corr1]= calculateStabilityCorr(obj,sections)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            time=obj.SpikeUnitTracked.Time;
            st=time.getStartTimeZT;et=time.getEndTimeZT;
            frames=linspace(st,et,sections+1);
            pfms=neuro.placeField.PlaceFieldMapMeasures.empty([sections 0]);
            for isec=1:sections
                frame=frames([isec isec+1]);
                try
                    pdsmall=obj.SpikeUnitTracked.PositionData.getWindow( ...
                        time.ZeitgeberTime( ...
                        frame,time.getZeitgeberTime));
                catch ME
                    
                end
                  
                sutsmall=obj.SpikeUnitTracked+pdsmall;
                frm=sutsmall.getFireRateMap(obj.XEdges,obj.ZEdges);
                pfm=frm.getPlaceFieldMap;
                pfms(isec)=pfm;
                mat(:,isec)=reshape(pfm.MapOriginal,[],1); %#ok<AGROW>
            end
            [corr1.R,corr1.P]=corr(mat);
            corr1.maps=pfms;
        end
        function [corr1]= calculateStabilityCorrLapbased(obj,sections)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            time=obj.SpikeUnitTracked.Time;
            pfms=neuro.placeField.PlaceFieldMapMeasures.empty( ...
                [height(sections) 0]);

            sut=obj.SpikeUnitTracked;
            for imap=1:height(sections)
                subste=sections(imap,:);
                wind=[subste.start subste.stop];
                windabs=time.getZeitgeberTime+wind;
                pdsmall=sut.PositionData.getTimeWindow(windabs);
                sutsmall=obj.SpikeUnitTracked+pdsmall;
                frm=sutsmall.getFireRateMap(obj.XEdges,obj.ZEdges);
                pfm=frm.getPlaceFieldMap;
                pfms(imap)=pfm;
                mat(:,imap)=reshape(pfm.MapOriginal,[],1); %#ok<AGROW>
            end
            [corr1.R,corr1.P]=corr(mat);
            corr1.maps=pfms;
        end
        function peaks = calculatePlaceFields(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            peaks1=obj.getPeakLocalMaxima;
            peaks=sortrows(peaks1,"FiringRate","descend");
        end
    end
end

