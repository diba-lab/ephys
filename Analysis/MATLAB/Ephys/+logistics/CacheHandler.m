classdef CacheHandler
    %CACHEHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CacheFolder
    end
    
    methods
        function obj = CacheHandler(cacheFolder)
            %CACHEHANDLER Construct an instance of this class
            %   Detailed explanation goes here
            obj.CacheFolder=cacheFolder;
        end
        function setFolder(obj,folder)
            if ~isfolder(folder)
                mkdir(folder);
                
            else
            end
            obj.Cachefolder=folder;
        end
        function outputArg = save(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            outputArg = obj.Property1 + inputArg;
        end
    end
end

