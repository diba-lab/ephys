classdef ProbeMeta < Persist
    %PROBEMETA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Type
        SiteSpatialLayout
        SiteSizesInUm
        Impedances
        OrientationOfProbe
        APCoordinate
        MLCoordinate
        APAngle
        MLAngle
        DepthFromSurface
    end
    
    methods
        function obj = ProbeMeta(file)
            %PROBEMETA Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@Persist(file);
            T=readtable(file,'ReadRowNames',true);
            obj.Type=T('Type',:).Value{:};
            obj.SiteSpatialLayout=T('SiteSpatialLayout',:).Value{:};
            obj.SiteSizesInUm=T('SiteSizesInUm',:).Value{:};
            obj.Impedances=T('Impedances',:).Value{:};
            obj.OrientationOfProbe=T('OrientationOfProbe',:).Value{:};
            obj.APCoordinate=T('APCoordinate',:).Value{:};
            obj.MLCoordinate=T('MLCoordinate',:).Value{:};
            obj.APAngle=T('APAngle',:).Value{:};
            obj.MLAngle=T('MLAngle',:).Value{:};
            obj.DepthFromSurface=T('DepthFromSurface',:).Value{:};
        end
        
        function save(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            S(1).Value=obj.Type;
            S(2).Value=obj.SiteSpatialLayout;
            S(3).Value=obj.SiteSizesInUm;
            S(4).Value=obj.Impedances;
            S(5).Value=obj.OrientationOfProbe;
            S(6).Value=obj.APCoordinate;
            S(7).Value=obj.MLCoordinate;
            S(8).Value=obj.APAngle;
            S(9).Value=obj.MLAngle;
            S(10).Value=obj.DepthFromSurface;
            rowNames={...
                'Type',...
                'SiteSpatialLayout',...
                'SiteSizesInUm',...
                'Impedances',...
                'OrientationOfProbe',...
                'APCoordinate',...
                'MLCoordinate',...
                'APAngle',...
                'MLAngle',...
                'DepthFromSurface',...
                };
            T=struct2table(S,'RowNames',rowNames);
            writetable(T,obj.FileLocation,'WriteRowNames',true);
        end
    end
end

