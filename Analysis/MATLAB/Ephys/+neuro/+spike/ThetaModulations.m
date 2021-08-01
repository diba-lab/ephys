classdef ThetaModulations
    %THETAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FitResult
        Gof
    end
    
    methods
        function obj = ThetaModulations(fitResult,gof)
            %THETAM Construct an instance of this class
            %   Detailed explanation goes here
            obj.FitResult = fitResult;
            obj.Gof=gof;
        end
        
        function thetaMagnitude = getThetaModulationMagnitudes(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            fitres=obj.FitResult;
%             gof=obj.Gof;
            thetaMagnitude=nan(numel(fitres),1);
            for isu=1:numel(fitres)
                fitres1=fitres{isu};
                %                 gof1=gof{isu};
                try
                    thetaMagnitude(isu)=fitres1.a/fitres1.b;
                catch
                end
            end
        end
        function thetaFreq = getThetaFrequency(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            fitres=obj.FitResult;
%             gof=obj.Gof;
            thetaFreq=nan(numel(fitres),1);
            for isu=1:numel(fitres)
                fitres1=fitres{isu};
                %                 gof1=gof{isu};
                try
                    thetaFreq(isu)=fitres1.w;
                catch
                end
            end
        end
    end
end

