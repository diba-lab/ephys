classdef PowerSpectrumCombined
    %POWERSPECTRUMCOMBINED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PowerSpectrums
    end
    
    methods
        function newobj = PowerSpectrumCombined(varargin)
            %POWERSPECTRUMCOMBINED Construct an instance of this class
            %   Detailed explanation goes here
            powerSpectrums=CellArrayList();
            for iArgIn=1:nargin
                powerSpectrum=varargin{iArgIn};
                assert(isa(powerSpectrum,'PowerSpectrum'));
                powerSpectrums.add(powerSpectrum);
                warning(sprintf('Record addded:\n%s\n', powerSpectrum.print))
            end
            newobj.PowerSpectrums=powerSpectrums;
        end
        
        function obj=plus(obj,varargin)
            for iArgIn=1:(nargin-1)
                powerSpectrum=varargin{iArgIn};
                assert(isa(powerSpectrum,'PowerSpectrum'));
                obj.PowerSpectrums.add(powerSpectrum);
                warning(sprintf('Record addded:\n%s\n', powerSpectrum.print))
            end
        end
        
        function obj = removeAPowerSpectrum(obj,theNumberOfPowerSpectrum)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.PowerSpectrums(theNumberOfPowerSpectrum)=[];
        end
        
        function print(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            iterator=obj.getIterator();
            while(iterator.hasNext())
                aPowerSpectrum=iterator.next();
                aPowerSpectrum.print();
            end
        end

        
    end
        %% Private Functions
    methods (Access=public)
        function iterator=getIterator(obj)
            iterator=obj.PowerSpectrums.createIterator;
        end
    end

end

