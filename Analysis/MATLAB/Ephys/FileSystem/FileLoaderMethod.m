classdef (Abstract) FileLoaderMethod
    %FILELOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
   
    end
    methods (Abstract)
        load(obj,filePath)
    end
    
    methods
        function obj = FileLoaderMethod()
            %FILELOADER Construct an instance of this class
            %   Detailed explanation goes here
        end
    end
end
