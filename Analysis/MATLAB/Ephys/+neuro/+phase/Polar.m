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
        function h=plotHist(obj,color)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            h=polarhistogram(obj.getPhase,0:pi/12:2*pi,'Normalization','count');
            if exist('color','var')
                h.FaceColor=color;
            end
        end
        function s=plotScatter(obj,rholim,color)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mpa=.5;
            r=rand(1,numel(obj.getPhase));
            if exist('rholim','var')
                r=normalize(r,'range',[rholim*.3 rholim]);
            else
                r=normalize(r,'range',[.3 1]);
            end
            if ~exist('color','var')
                s=polarscatter(obj.getPhase,r,"filled",MarkerFaceAlpha=mpa);
            else
                s=polarscatter(obj.getPhase,r,[],color,"filled",MarkerFaceAlpha=mpa);
            end
        end
        function ax=plotLegendAndColors(obj,ax)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t=linspace(0,.250,250);
            y=sin(8*t*2*pi);
            y1=neuro.basic.Channel('',y,neuro.time.TimeInterval(datetime('today'),1000,numel(t)));
            y1ph=y1.getHilbertPhase;
            y1ph.plot
            
        end
        function ax=plotPolarColors(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ax=gca;
            rho=ax.RLim(2);
            theta=linspace(-pi,pi,200);
            numcolors=64;
            colors = [0.9612 0.4459 0.4459;0.9475 0.4615 0.4019;0.9305 0.4783 0.3598;0.9102 0.4963 0.3201;0.887 0.5154 0.283;0.8611 0.5352 0.2489;0.8326 0.5557 0.2183;0.8019 0.5765 0.1913;0.7692 0.5977 0.1683;0.7349 0.6188 0.1494;0.6993 0.6397 0.1348;0.6628 0.6603 0.1248;0.6256 0.6803 0.1193;0.5882 0.6995 0.1184;0.5509 0.7178 0.1222;0.5141 0.7349 0.1306;0.4781 0.7507 0.1435;0.4433 0.7651 0.1608;0.41 0.7779 0.1823;0.3785 0.789 0.2079;0.3492 0.7982 0.2372;0.3222 0.8056 0.27;0.298 0.8109 0.306;0.2766 0.8143 0.3449;0.2584 0.8155 0.3861;0.2435 0.8147 0.4295;0.232 0.8118 0.4745;0.224 0.8069 0.5207;0.2197 0.8 0.5676;0.219 0.7912 0.6149;0.222 0.7805 0.662;0.2286 0.7681 0.7086;0.2388 0.7541 0.7541;0.2525 0.7385 0.7981;0.2695 0.7217 0.8402;0.2898 0.7037 0.8799;0.313 0.6846 0.917;0.3389 0.6648 0.9511;0.3674 0.6443 0.9817;0.4024 0.623 1;0.4432 0.6022 1;0.4802 0.5833 1;0.5146 0.5658 1;0.5472 0.5492 1;0.5787 0.5332 1;0.6098 0.5173 1;0.6411 0.5014 1;0.6732 0.485 1;0.7068 0.4679 1;0.7427 0.4496 1;0.782 0.4296 1;0.8215 0.411 0.9921;0.8508 0.4018 0.9628;0.8778 0.3944 0.93;0.902 0.3891 0.894;0.9234 0.3857 0.8551;0.9416 0.3845 0.8139;0.9565 0.3853 0.7705;0.968 0.3882 0.7255;0.976 0.3931 0.6793;0.9803 0.4 0.6324;0.981 0.4088 0.5851;0.978 0.4195 0.538;0.9714 0.4319 0.4914];
            phaseidx=round(normalize(theta,'range',[.5+eps numcolors+.5-.0001]));
            color=colors(phaseidx,:);
            polarscatter(theta,rho,[],color,"filled");
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
%             [p, U, UC]=obj.getTestRaosSpacing();
%             if p<.01
%                 txt=sprintf('Not uniform RAO, p=%.3f, U=%.2f, UC=%.2f',p,U,UC);
%                 color="#A2142F";
%             else
%                 txt=sprintf('Uniform RAO, p=%.3f, U=%.2f, UC=%.2f',p,U,UC);
%                 color="#77AC30";
%             end
%             text(x,y,txt,Color=color, ...
%                 Units="characters",HorizontalAlignment="center");y=y-1;
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
        function [rho, pval] =getTestCorrcl(obj,linearpoints)
            [rho, pval] =circ_corrcl(obj.getPhase,linearpoints);
        end
        function [rho, pval] =getTestCorrcc(obj,theta)
            [rho, pval] =circ_corrcc(obj.getPhase(),theta);
        end
        function [pval, k, K] =compareKS(obj,other)
            [pval, k, K] =circ_kuipertest(obj.getPhase(),other.getPhase);
        end


    end
end

