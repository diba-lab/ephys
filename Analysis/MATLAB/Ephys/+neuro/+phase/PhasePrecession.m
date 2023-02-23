classdef PhasePrecession < neuro.phase.SpikePhases
    %PHASEPRECESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Position
    end
    
    methods
        function obj = PhasePrecession(spikePhases,position)
            %PHASEPRECESSION Construct an instance of this class
            %   Detailed explanation goes here
            fnames=fieldnames(spikePhases);
            for ifn=1:numel(fnames)
                fname=fnames{ifn};
                obj.(fname)=spikePhases.(fname);
            end
            obj.Position=position;
        end
        function obj = getPlaceField(obj)
            %PHASEPRECESSION Construct an instance of this class
            %   Detailed explanation goes here
            x=obj.Position.X;
            [a,b]=histcounts(obj.Position.X,"BinWidth",1);a=smoothdata(a,'gaussian',50);
            [pks,locs,w,p] =findpeaks(a);s.pks=pks';s.locs=locs';s.w=w';s.p=p';
            t1=struct2table(s);t1=sortrows(t1,"p","descend");
            try
                p1=t1(1,:);
                idx=round([p1.locs-p1.w*.7 p1.locs+p1.w*.7]);
                if numel(b)<idx(2)
                    idx(2)=numel(b);
                end
                if idx(1)<1
                    idx(1)=1;
                end
                pfwin=b(idx);
            catch ME
                
            end
            inpf=x>=pfwin(1)&x<=pfwin(2);
            obj.Position=obj.Position(inpf,:);
            obj.PolarData=obj.PolarData(inpf,:);
        end
        function tbl = getPhasePrecessionStats(obj)
            %PHASEPRECESSION Construct an instance of this class
            %   Detailed explanation goes here
            ph=obj.PolarData.Phase;
            x=obj.Position.X;
            dir=median(diff(x));
            if dir>0
                dirs=1;
            elseif dir<0
                dirs=-1;
            else
                dirs=0;
            end
            ph(isnan(x))=[];
            x(isnan(x))=[];
            a=fit(x,ph,'poly1');
            [rho, pval] = obj.getTestCorrcl(obj.Position.X);
            s.CorrR=rho;
            s.CorrP=pval;
            s.Slope=a.p1;
            s.Intercept=a.p2;
            s.Direction=dirs;
            tbl=struct2table(s);
        end
        
        function [] = plotPrecession(obj,color)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~exist("color","var")
                color=[];
            end
            colorsBlue=othercolor('Blues9',80);
            colorsMatlab=colororder;
            ph=obj.PolarData.Phase;
            m1=obj.getMean;
            idx=obj.PolarData.Phase>(m1+pi);
            if any(idx)
                obj.PolarData.Phase(idx)=obj.PolarData.Phase(idx)-2*pi;
            else
                idx=obj.PolarData.Phase<(m1-pi);
                obj.PolarData.Phase(idx)=obj.PolarData.Phase(idx)+2*pi;
            end
            ph1=obj.getPhase;
            x=obj.Position.X;
            s=scatter(x,ph1,[],color,"filled", ...
                MarkerFaceAlpha=.5);
            s.SizeData=10;
            ax=gca;
            ax.YTick=-3*pi:pi/2:pi;
            ax.YTickLabel={'\pi','-\pi/2','0','\pi/2','\pi',...
                '-\pi/2','0','\pi/2','\pi'};
            hold on;
            ax.YLim=[m1-pi m1+pi];
            yline(obj.getMean, LineStyle="--", LineWidth=1,...
                Color=colorsMatlab(1,:));
%             [N,Xedges,Yedges,binX,binY] = ...
%             histcounts2(x,ph1,[round(max(x)-min(x))*2 30],Normalization="pdf");
%             [X,Y] = meshgrid(Xedges(2:end),Yedges(2:end));
%             N1=imgaussfilt(N,5);
%             colormap(ax,colorsBlue(3:end,:));
%             [~,c]=contour(X,Y,N1',5,LineWidth=1);
            idx=isnan(x)|isnan(ph1);
            x(idx)=[];
            ph1(idx)=[];
            obj.Position(idx,:)=[];
            obj.PolarData(idx,:)=[];
            a=fit(x,ph1,'poly1');
            x1=linspace(min(x),max(x),20);
            try
                [rho, pval] = obj.getTestCorrcl(x);
            catch ME
                
            end
            if pval<.05
                str=sprintf('Corr Pos x Phase');
                text(5,6,str,Units="characters",Color=colorsMatlab(3,:));
                plot(x1,a.p1*x1+a.p2,"Color",colorsMatlab(1,:),LineWidth=2);

            else
                str=sprintf('No Corr Pos x Phase');
                text(5,6,str,Units="characters",Color=colorsMatlab(2,:));                
                plot(x1,a.p1*x1+a.p2,"Color",colorsMatlab(1,:),LineWidth=1);
            end
            text(5,5,sprintf('rho=%.3f, p=%.3f',rho,pval),Units="characters");
        end
    end
end

