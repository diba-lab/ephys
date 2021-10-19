classdef SleepCluster
%STRATEGY Summary of this class goes here
%   Detailed explanation goes here

   properties
       m_Type = {};
   end

   methods
       function obj = SleepCluster(value,param)
            obj=obj.SetClusterType(value,param);
       end
       
       function obj= SetClusterType(obj, value,param)
            obj.m_Type = ClusterType.newType(value,param); 
       end
       
       function cluster=runCluster(obj, ts)
            cluster=obj.m_Type.runCluster(ts);
       end
   end
end 
