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
            duration=1.4;
            binsize=.01;
            obj.Count=nan(numel(spikeUnits),duration/binsize+1);
            sucount=1;
            for isu=1:numel(spikeUnits)
                spikeUnit=spikeUnits(isu);
                sample=spikeUnit.getTimes;
                if numel(sample.sample)>0
                    times=seconds(sample.getDuration);
                    try
                        [obj.Count(sucount,:),obj.Time]=CCG(times,ones(size(times)),...
                            'duration', duration,...
                            'binSize', binsize,...
                            'Fs',1/sample.rate,...
                            'normtype', 'count');
                        sucount=sucount+1;
                        obj.Info=[obj.Info;spikeUnit.Info];
                    catch
                    end
                end
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
                countmax=max(mat(isu,tind));
                mat(isu,:)=mat(isu,:)/countmax;
            end
            obj.Count=mat;
        end
        function obj=getACGWithCountLessThan(obj, count)
            mat=obj.Count;
            t=obj.Time;
            idx=t>.070&t>.200;
            idx2=mean(mat(:,idx),2)<count;
            obj.Count=mat(idx2,:);
            obj.Info =obj.Info(idx2,:);            
        end
        function obj=getACGWithCountBiggerThan(obj, count)
            mat=obj.Count;
            t=obj.Time;
            idx=t>.070&t>.200;
            idx2=mean(mat(:,idx),2)>=count;
            obj.Count=mat(idx2,:);
            obj.Info =obj.Info(idx2,:);
        end
        
        function [thetaMod] = getThetaModulations(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            count=obj.Count;
            t=obj.Time';
            for isu=1:size(count,1)
                line=count(isu,:);
                try
                    [fitresult, gof] = neuro.spike.createFit(t,line);
                    fitresults{isu}=fitresult;
                    gofs{isu}=gof;
                catch
                end
            end
            thetaMod=neuro.spike.ThetaModulations(fitresults,gofs);
        end
        function [t_freq,t_pow] = getThetaPeaksLocalmax(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            count=obj.Count;
            t=obj.Time';
            t_freq=nan(size(count,1),1);
            t_pow=nan(size(count,1),1);
            for isu=1:size(count,1)
                line=count(isu,:);
                t_new=linspace(t(1),t(end),numel(t)*10);
                line_new=spline(t, line, t_new);
                line_bp=ft_preproc_bandpassfilter(line_new,1000,[6 25]);
%                 plot(t_new, line_bp)
%                 hold on
                t_range=t_new>1.000/10&t_new<1.000/5;
                line_interest=line_bp(t_range);
                t_interest=t_new(t_range);
                [pwr,locs] = findpeaks(line_interest,'SortStr','descend');
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
%             thetaMod= obj.getThetaModulations;
%             t_mag=thetaMod.getThetaModulationMagnitudes;
            mat1=obj.Count;
            [t_freq1, t_pow]=obj.getThetaPeaksLocalmax;
            tbl.thetaFreq(:)=t_freq1(:);

            unit_interst=t_pow>.05;
            mat=mat1(unit_interst,:);
            tbl=tbl(unit_interst,:);
%             t_freq=thetaMod.getThetaFrequency;
%             [t_mag,ind]=sort(t_mag,'ascend');
%                       t_freq=t_freq(ind);
            if exist("sort1","var")
                [tbl,ind]=sortrows(tbl,[sort1 "thetaFreq"]);
            else
                [tbl,ind]=sortrows(tbl,"thetaFreq");
            end
%             t_mag=t_mag(ind);
            %             [~,idx]=sort(mean(mat,2));
            mat=mat(ind,:);
            peak=double(1)./tbl.thetaFreq;
            mat=imgaussfilt(mat,.5);
            imagesc(obj.Time,1:size(mat,1),mat)
            ax=gca;
            ax.CLim=[.7 1.2];
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
            [pks,locs] =findpeaks(popmean(:,t_interest),new_t(t_interest),'NPeaks',1);
            p=plot(new_t,popmean);
            p.LineWidth=2;
            p.Color='#A2142F';
            ax.YDir='normal';
            freq=1/locs(1);
            s3=scatter([-locs locs],[pks pks],'v','filled','MarkerFaceColor','#A2142F');
            t=text(locs,pks,sprintf('%.2fHz',freq),'VerticalAlignment','bottom','HorizontalAlignment','center');
            t.FontSize=10;
            t.Color='#A2142F';
            units_interest=1:numel(tbl.thetaFreq);
            mean_inter_peak=peak(units_interest);
            treq_mean_peak=mean(mean_inter_peak);            
%             eb=errorbar(treq_mean_peak,numel(t_freq)/2,std(mean_inter_peak)/sqrt(numel(mean_inter_peak)),'horizontal');
            xl=xline(treq_mean_peak);
            xl.Color=colors_peak(1,:);
            xl.LineWidth=1;
            t2=text(treq_mean_peak,numel(tbl.thetaFreq)/2,sprintf('%.2fHz',1/treq_mean_peak),'VerticalAlignment','bottom','HorizontalAlignment','center');
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
                text(1,.5-.1*(mean(1:height(type))-ity),txt,'Color',colors_peak(ity,:),Units='normalized')
            end
        end
    end
end

