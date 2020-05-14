classdef KMeansCluster < ClusterType
%SimpleMA Summary of this class goes here
%   Detailed explanation goes here
% This class has a contract with the StrategyType Interface. It must
% deliver a RunStrategy method that takes in a TimeSeries class

   properties
       K
   end

   methods
       function obj = KMeansCluster(param)
          obj.K=param.K;
       end
       function cluster = runCluster(obj, allday)
          [G,C] = kmeans(allday, obj.K, 'Display','iter',...
        'distance','sqeuclidean',...
        'start','uniform',...
        'EmptyAction','drop',...
        'MaxIter',1000);
        cluster=KMeansClusterResult(G,C,allday);
       end
       
   end
end 