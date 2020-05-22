classdef DBScanCluster < ClusterType
%SimpleMA Summary of this class goes here
%   Detailed explanation goes here
% This class has a contract with the StrategyType Interface. It must
% deliver a RunStrategy method that takes in a TimeSeries class

   properties
       epsilon
       minpts
   end

   methods
       function obj = DBScanCluster(param)
          obj.epsilon=param.epsilon;
          obj.minpts=param.minpts;
       end
       function cluster = runCluster(obj, allday)
        G = dbscan(allday,obj.epsilon,obj.minpts);
        
        cluster=DBScanClusterResult(G,allday);
       end
       
   end
end 