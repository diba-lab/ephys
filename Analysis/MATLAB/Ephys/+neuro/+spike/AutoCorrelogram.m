classdef AutoCorrelogram
    %AUTOCORRELOGRAMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Count
        Time
        Info
    end
    
    methods
        function obj = AutoCorrelogram(spikeUnits)
            %AUTOCORRELOGRAMS Construct an instance of this class
            %   Detailed explanation goes here
            if exist("spikeUnits","var")
                duration=1.4;
                binsize=.001;
                obj.Count=nan(numel(spikeUnits),int64(duration/binsize+1));
                sucount=1;
                obj.Info=[];
                for isu=1:numel(spikeUnits)
                    spikeUnit=spikeUnits(isu);
                    sample=spikeUnit.getTimes;
                    if numel(sample.sample)>0
                        times=seconds(sample.getDuration);
                        [obj.Count(sucount,:),obj.Time]=CCG(times,ones(size(times)),...
                            'duration', duration,...
                            'binSize', binsize,...
                            'Fs',1/sample.rate,...
                            'normtype', 'count');
                        sucount=sucount+1;
                        obj.Info=[obj.Info;spikeUnit.Info];
                    end
                end
                obj.Count(sucount:end,:)=[];
            end
        end
        function obj=plus(obj, new)
            obj.Count=[obj.Count; new.Count];
            obj.Info=[obj.Info; new.Info];
        end
        function obj=getNormalized(obj, win)
            mat=obj.Count;
            t=obj.Time;
            tind=(t>=win(1))&(t<=win(2));
            for isu=1:size(mat,1)
                min1=min(mat(isu,tind));
                max1=max(mat(isu,tind));
                mat(isu,:)=(mat(isu,:)-min1)/max1;
            end
            obj.Count=mat;
        end
        function obj=getSmooth(obj, points,dim)
            obj.Count=smoothdata(obj.Count,dim,"gaussian",points,"omitmissing");
        end

        function obj=getACGWithCountLessThan(obj, count)
            mat=obj.Count;
            t=obj.Time;
            idx=t>.080&t<.200;
            idx2=mean(mat(:,idx),2)<count;
            obj.Count=mat(idx2,:);
            obj.Info =obj.Info(idx2,:);            
        end
        function obj=getACGWithCountBiggerThan(obj, count)
            mat=obj.Count;
            t=obj.Time;
            idx = t>.080 & t<.200;
            idx2=mean(mat(:,idx),2)>=count;
            obj.Count=mat(idx2,:);
            obj.Info =obj.Info(idx2,:);
        end
        
        function [thetaMod] = getThetaModulations(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            count=obj.Count;
            t=obj.Time;
            fitresults=cell(size(count,1),1);gofs=cell(size(count,1),1);
            for isu=1:size(count,1)
                line=count(isu,:);
                try
                    if ~all(size(t)==size(line))
                        t=t';
                    end
                    [fitresult, gof] = neuro.spike.createFit(t,line);
                    fitresults{isu}=fitresult;
                    gofs{isu}=gof;
                catch
                end
            end
            thetaMod=neuro.spike.ThetaModulations(fitresults,gofs);
        end
        function [tres] = getThetaModulationsTable(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            tm=obj.getThetaModulations;
            a=nan(numel(tm.FitResult),1);
            b=nan(numel(tm.FitResult),1);
            c=nan(numel(tm.FitResult),1);
            d=nan(numel(tm.FitResult),1);
            t1=nan(numel(tm.FitResult),1);
            t2=nan(numel(tm.FitResult),1);
            w=nan(numel(tm.FitResult),1);
            sse=nan(numel(tm.FitResult),1);
            rsquare=nan(numel(tm.FitResult),1);
            dfe=nan(numel(tm.FitResult),1);
            adjrsquare=nan(numel(tm.FitResult),1);
            rmse=nan(numel(tm.FitResult),1);
            for i=1:numel(tm.FitResult)
                fr=tm.FitResult{i};
                gof=tm.Gof{i};
                try
                    a(i,1)=fr.a;
                    b(i,1)=fr.b;
                    c(i,1)=fr.c;
                    d(i,1)=fr.d;
                    t1(i,1)=fr.t1;
                    t2(i,1)=fr.t2;
                    w(i,1)=fr.w;
                    sse(i,1)=gof.sse;
                    rsquare(i,1)=gof.rsquare;
                    dfe(i,1)=gof.dfe;
                    adjrsquare(i,1)=gof.adjrsquare;
                    rmse(i,1)=gof.rmse;
                catch
                end
            end
            tres=array2table([a b c d t1 t2 w a./b sse rsquare dfe ...
                adjrsquare rmse],VariableNames={ ...
                'a','b','c','d','t1','t2','w','power','sse','rsquare','dfe' ...
                ,'adjrsquare','rmse'});
        end
        function [t_freq,t_pow] = getThetaPeaksLocalmax(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ft_defaults
            count=obj.Count;
            t=obj.Time';
            t_freq=nan(size(count,1),1);
            t_pow=nan(size(count,1),1);
            for isu=1:size(count,1)
                line=count(isu,:);
                
%                 plot(t_new, line_bp)
%                 hold on
                t_range=t>1.000/10&t<1.000/5;
                line_interest=line(t_range);
                t_interest=t(t_range);
                [pwr,locs] = builtin('findpeaks',line_interest,'SortStr','descend');
                if numel(locs)>0
                    peaktime=t_interest(locs(1));
                    t_freq(isu)=1/peaktime;
                    t_pow(isu)=pwr(1);
                end
            end
        end
        function [count, t] = getCount(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            count=obj.Count;
            t=obj.Time;
        end
        function [tbl]=plot(obj,group,sort1)
            tbl=obj.Info;
            [type,~,gr]=unique(tbl(:,group));

            colors_peak=linspecer(height(type));

            for ig=1:numel(gr)
                colors(ig,:)=colors_peak(gr(ig),:);
            end
            tbl.color=colors;
            thetaMod= obj.getThetaModulations;
            t_freq=thetaMod.getThetaFrequency;
            % mat1=obj.Count;
            % [t_freq1, t_pow]=obj.getThetaPeaksLocalmax;
            tbl.thetaFreq(:)=t_freq(:);

            % unit_interst=t_pow>.05;
            % mat=mat1(unit_interst,:);
            % tbl=tbl(unit_interst,:);
%             t_freq=thetaMod.getThetaFrequency;
            [t_freq,indf]=sort(t_freq,'ascend');
            if exist("sort1","var")
                [tbl,ind]=sortrows(tbl,[sort1 "thetaFreq"]);
            else
                [tbl,ind]=sortrows(tbl,"thetaFreq");
            end
%             t_mag=t_mag(ind);
            %             [~,idx]=sort(mean(mat,2));
            mat=obj.Count(indf,:);
            peak=double(1)./tbl.thetaFreq;
            imagesc(obj.Time,1:size(mat,1),mat);
            hold on
            ax=gca;
            ax.CLim=[0 1];
            colormap('pink');
            popmean=mean(mat)*size(mat,1)/5;
            new_t=min(obj.Time):.001:max(obj.Time);
            popmean=spline(obj.Time,popmean,new_t);
            hold on;
            s1=scatter(peak,1:size(mat,1),15,tbl.color);
            s1.MarkerEdgeAlpha=.7;
            s2=scatter(2*peak,1:size(mat,1),10,tbl.color);
            s2.MarkerEdgeAlpha=.7;

            t_interest=new_t>.05&new_t<.200;
            [pks,locs] =findpeaks(popmean(:,t_interest),new_t(t_interest), ...
                'NPeaks',1);
            p=plot(new_t,popmean);
            p.LineWidth=2;
            p.Color='#A2142F';
            ax.YDir='normal';
            freq=1/locs(1);
            s3=scatter([-locs locs],[pks pks],'v','filled', ...
                'MarkerFaceColor','#A2142F');
            t=text(locs,pks,sprintf('%.2fHz',freq), ...
                'VerticalAlignment','bottom','HorizontalAlignment','center');
            t.FontSize=10;
            t.Color='#A2142F';
            units_interest=1:numel(tbl.thetaFreq);
            mean_inter_peak=peak(units_interest);
            treq_mean_peak=mean(mean_inter_peak);            
%             eb=errorbar(treq_mean_peak,numel(t_freq)/2, ...
% std(mean_inter_peak)/sqrt(numel(mean_inter_peak)),'horizontal');
            xl=xline(treq_mean_peak);
            xl.Color=colors_peak(1,:);
            xl.LineWidth=1;
            t2=text(treq_mean_peak,numel(tbl.thetaFreq)/2,sprintf('%.2fHz', ...
                1/treq_mean_peak),'VerticalAlignment','bottom', ...
                'HorizontalAlignment','center');
            t2.Color=xl.Color;
            t2.FontSize=10;
            ax.XLim=[0 .400];
            for ity=1:height(type)
                txt2=table2cell(type(ity,:));
                try
                    for it=1:numel(txt2),txt2{it}=txt2{it}(1:3);end
                catch
                end
                txt=strjoin(txt2);
                text(1,.5-.1*(mean(1:height(type))-ity),txt, ...
                    'Color',colors_peak(ity,:),Units='normalized')
            end
        end
        function []=plotSingle(obj)
            plot(obj.Time,obj.Count);
            ax=gca;
            ax.XLim=[0 .5];
            tm=obj.getThetaModulations;
            fr=tm.FitResult;
            hold on;
            plot(fr{:})
            text(.95,.95,sprintf('theta magnitude:%.3f\ntheta frequency:%.3f', ...
                tm.getThetaModulationMagnitudes,tm.getThetaFrequency), ...
                Units="normalized",HorizontalAlignment="right", ...
                VerticalAlignment="top")
            xline(1/tm.getThetaFrequency)
        end
    end
end

