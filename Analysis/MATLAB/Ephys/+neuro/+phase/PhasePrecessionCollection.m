classdef PhasePrecessionCollection
    %PHASEPRECESSIONCOLLECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PhasePrecessions
    end
    
    methods
        function obj = PhasePrecessionCollection(phasePrecessions)
            %PHASEPRECESSIONCOLLECTION Construct an instance of this class
            %   Detailed explanation goes here
            obj.PhasePrecessions=neuro.phase.PhasePrecession.empty(0);
            if nargin>0
                for iph=1:numel(phasePrecessions)
                    php=phasePrecessions(iph);
                    obj=obj.add(php);
                end
            else

            end
        end
        
        function obj = add(obj,php)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.PhasePrecessions(numel(obj.PhasePrecessions)+1)=php;
        end
        function obj = getUnits(obj,idx)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.PhasePrecessions=obj.PhasePrecessions(idx);
        end
        function tbl = getPhasePrecessionInfoTable(obj)
            for ipp=1:numel(obj.PhasePrecessions)
                pp=obj.PhasePrecessions(ipp);
                t1=struct2table(pp.getStats);
                [s.Rayleigh_p, s.Rayleigh_z]=pp.getTestRayleigh;
                [s.Omnibus_p, s.Omnibus_z]=pp.getTestOmnibus;
%                 pp1=pp.getPlaceField;
                t2=[pp.getPhasePrecessionStats t1 struct2table(s)];
%                 pp1.plotPrecession
                
                if exist("tbl","var")
                    tbl=[tbl; t2];
                else
                    tbl=t2;
                end
            end
        end

    end
end

