classdef Polar
    %POLAR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PolarData
    end
    
    methods
        function obj = Polar(varargin)
            %POLAR Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                obj.PolarData=varargin{1};
            end
        end
        
        function phase=getPhase(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            phase=obj.PolarData;
        end
        function h=plotHist(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            h=polarhistogram(obj.getPhase,varargin{:});
        end
        function s=plotScatter(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            r=rand(1,numel(obj.getPhase));
            s=polarscatter(obj.getPhase,r,"filled",MarkerFaceAlpha=.2);
        end       
        function plotStats(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            h=obj.plotHist;
            h.DisplayStyle="stairs";
            h.Normalization="pdf";
            h.LineWidth=1;h.EdgeColor=[.4 .4 .4];
            hold on;
            [mu, ul, ll]=obj.getMean;
            len1=obj.getResultantVectorLength;
            ax=gca;
            m=polarplot([ul ul],[0 ax.RLim(2)]);
            m.LineWidth=1;m.Color=[.8 .8 .8];
            m=polarplot([ll ll],[0 ax.RLim(2)]);
            m.LineWidth=1;m.Color=[.8 .8 .8];
            m=polarplot([mu mu],[0 len1]);
            m.LineWidth=2;m.Color="#A2142F";
            ax.ThetaAxisUnits="radians";
            x=25;
            y=8;
            [pval, z] =obj.getTestRayleigh;
            if pval<.01
                txt=sprintf('Not uniform Rayleigh, p=%.3f, z=%.2f',pval,z);
                color="#A2142F";
            else
                txt=sprintf('Uniform Rayleigh, p=%.3f, z=%.2f',pval,z);
                color="#77AC30";
            end
            text(x,y,txt,Color=color, ...
                Units="characters",HorizontalAlignment="center");y=y-1;

            [pval, m]=obj.getTestOmnibus;
            if pval<.01
                txt=sprintf('Not uniform Omnibus, p=%.3f, m=%.2f',pval,m);
                color="#A2142F";
            else
                txt=sprintf('Uniform Omnibus, p=%.3f, m=%.2f',pval,m);
                color="#77AC30";
            end
            text(x,y,txt,Color=color, ...
                Units="characters",HorizontalAlignment="center");y=y-1;
            [p, U, UC]=obj.getTestRaosSpacing();
            if p<.01
                txt=sprintf('Not uniform RAO, p=%.3f, U=%.2f, UC=%.2f',p,U,UC);
                color="#A2142F";
            else
                txt=sprintf('Uniform RAO, p=%.3f, U=%.2f, UC=%.2f',p,U,UC);
                color="#77AC30";
            end
            text(x,y,txt,Color=color, ...
                Units="characters",HorizontalAlignment="center");y=y-1;
            polarscatter(obj.getMedian,ax.RLim(2),"filled", ...
                MarkerFaceColor="#EDB120",MarkerFaceAlpha=.5)
            polarscatter(obj.getMean,ax.RLim(2),"filled", ...
                MarkerFaceColor="#A2142F",MarkerFaceAlpha=.5)
            [b, b0]=obj.getSkewness;
            text(x,y,sprintf('Skewness=%.3f, %.3f',b,b0), ...
                Units="characters",HorizontalAlignment="center", ...
                Color=	"#0072BD");y=y-1;
            [k, k0]=obj.getKurtosis;
            text(x,y,sprintf('Kurtosis=%.3f, %.3f',k,k0), ...
                Units="characters",HorizontalAlignment="center", ...
                Color=	"#0072BD");y=y-1;
        end
        function r=getResultantVectorLength(obj)
            r=circ_r(obj.getPhase());
        end
        function [mu, ul, ll]=getMean(obj)
            [mu, ul, ll]=circ_mean(obj.getPhase());
        end
        function r=getMedian(obj)
            r=circ_median(obj.getPhase());
        end
        function [S, s]=getVariance(obj)
            [S, s]=circ_var(obj.getPhase());
        end
        function [s, s0] =getStandardDeviation(obj)
            [s, s0] =circ_std(obj.getPhase());
        end
        function [b, b0] =getSkewness(obj)
            [b, b0] =circ_skewness(obj.getPhase());
        end
        function [k, k0]=getKurtosis(obj)
            [k, k0]=circ_kurtosis(obj.getPhase());
        end
        function r=getStats(obj)
            r=circ_stats(obj.getPhase());
        end

        function [pval, z] =getTestRayleigh(obj)
            [pval, z] =circ_rtest(obj.getPhase());
        end
        function [pval, m]=getTestOmnibus(obj)
            [pval, m]=circ_otest(obj.getPhase());
        end
        function [p, U, UC]=getTestRaosSpacing(obj)
            [p, U, UC]=circ_raotest(obj.getPhase());
        end
        function [h, mu, ul, ll]=getTestOneSampleForMean(obj,angleRadian)
            [h, mu, ul, ll]=circ_mtest(obj.getPhase(),angleRadian);
        end
        function pval=getTestOneSampleForMedian(obj,angleRadian)
            pval=circ_medtest(obj.getPhase(),angleRadian);
        end
        function pval=getTestSymmetryArounMedian(obj)
            pval=circ_symtest(obj.getPhase());
        end

        function [thetahat, kappa]=getPdfEstimate(obj)
            [thetahat, kappa]=circ_vmpar(obj.getPhase());
        end


    end
end

