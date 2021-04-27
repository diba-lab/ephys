classdef KMeansClusterResult < ClusterResult
    %CLUSTERRESULT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        G
        C
        data
    end
    
    methods
        function obj = KMeansClusterResult(G,C,data)
            %CLUSTERRESULT Construct an instance of this class
            %   Detailed explanation goes here
            obj.G = G;
            obj.C = C;
            obj.data = data;
        end
        
        function [] = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            G=obj.G;
            C=obj.C;
            allday=obj.data;
            %# show points and clusters (color-coded)
            clr = lines(size(C,1));
            figure, hold on
            scatter3(allday(:,1), allday(:,2), allday(:,3), 36, clr(G,:), 'Marker','.')
            scatter3(C(:,1), C(:,2), C(:,3), 100, 'k', 'Marker','o', 'LineWidth',3)
            hold off
        end
    end
end

