classdef ClusterType
% Interface / Abstract Class 
% This class must be inherited. The child class must deliver the
% RunStrategy method that accept the TimeSeries class

   properties
   end

   methods (Abstract)
       [clusteredData]=runCluster(ts)
   end
   
   methods (Static)
       function rslt = newType(value,param)
          switch lower(value)
              case 'kmeans'
                  rslt = KMeansCluster(param);
              case 'dbscan'
                  rslt = DBScanCluster(param);
                % If you want to add more strategies, simply put them in
                % here and then create another class file that inherits
                % this class and implements the RunStrategy method
              otherwise
                  error('Type must be either kmeans or dbscan');
          end
       end
   end
end 