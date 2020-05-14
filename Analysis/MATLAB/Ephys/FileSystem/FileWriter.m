classdef FileWriter < Singleton
    %FILEWRITER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       ChunksSize
       FileName
       FileID
       isopen
    end
    
    methods (Access=private)
        function obj = FileWriter(filename)
            %FILEWRITER Construct an instance of this class
            %   Detailed explanation goes here
            obj.ChunksSize=1e6;
            obj.FileName=filename;
            obj.isopen=0;
        end
        
    end
    methods(Static)
      % Concrete implementation.  See Singleton superclass.
      function obj = instance(filename)
         persistent uniqueInstance
         if isempty(uniqueInstance)
            obj = FileWriter(filename);
            uniqueInstance = obj;
         else
            obj = uniqueInstance;
         end
      end
   end
    
    methods 
            
        
        function count = addSection(obj,chunk)
            if ~obj.isopen
            obj.FileID=fopen(obj.FileName,'a');
            obj.isopen=1;
            end
                
            count = fwrite(obj.FileID, chunk, 'int16');
        end
        function status = close(obj)
            status = fclose(obj.FileID);
            obj.isopen=0;
        end
        function obj = open(obj)
            obj.FileID=fopen(obj.FileName,'a');
            obj.isopen=1;
        end
    end
end

