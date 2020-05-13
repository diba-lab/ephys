classdef (Abstract) Topography2D
    %2DMAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        topography
        xBins
        yBins
    end
    
    methods (Abstract)
        plot(obj,varargin)
    end
    
    methods
        function obj = Topography2D(topography,xBins,yBins)
            %2DMAP Construct an instance of this class
            %  	TODOs
            %   compatibility test
            obj.topography=topography;
            obj.xBins=xBins;
            obj.yBins=yBins;
        end
        function obj=setxBins(obj,xbins)
            obj.xBins=xbins;
            
        end
        function outputArg = getSubTopography(obj, xInterests, yInterests)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

