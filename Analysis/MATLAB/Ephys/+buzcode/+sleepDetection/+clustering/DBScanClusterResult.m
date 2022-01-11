classdef DBScanClusterResult < ClusterResult
    %CLUSTERRESULT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        G
        data
    end
    
    methods
        function obj = DBScanClusterResult(G,data)
            %CLUSTERRESULT Construct an instance of this class
            %   Detailed explanation goes here
            obj.G = G;
            obj.data = data;
        end
        
        function [] = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            IDX=obj.G;
            X=obj.data;
            IDX(IDX==-1)=0;
            k=max(IDX);
            
            Colors=hsv(k);
            
            Legends = {};
            for i=0:k
                Xi=X(IDX==i,:);
                if i~=0
                    Style = '.';
                    MarkerSize = 5;
                    Color = Colors(i,:);
                    Legends{end+1} = ['Cluster #' num2str(i)];
                else
                    Style = '.';
                    MarkerSize = 3;
                    Color = [0 0 0];
                    if ~isempty(Xi)
                        Legends{end+1} = 'Noise';
                    end
                end
                if ~isempty(Xi)
                    plot3(Xi(:,1),Xi(:,2),Xi(:,3),Style,'MarkerSize',MarkerSize,'Color',Color);
                end
                hold on;
            end
            hold off;
            axis equal;
            grid on;
            legend(Legends);
            legend('Location', 'NorthEastOutside');
        end
    end
end

