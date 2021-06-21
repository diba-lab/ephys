classdef AutoCorrelogram
    %AUTOCORRELOGRAMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Count
        Time
    end
    
    methods
        function obj = AutoCorrelogram(spikeUnits)
            %AUTOCORRELOGRAMS Construct an instance of this class
            %   Detailed explanation goes here
            duration=1.4;
            binsize=.01;
            obj.Count=nan(numel(spikeUnits),duration/binsize+1);
            for isu=1:numel(spikeUnits)
                spikeUnit=spikeUnits(isu);
                sample=spikeUnit.getTimes;
                if numel(sample.Samples)>0
                    times=seconds(sample.getDuration);
                    try
                    [obj.Count(isu,:),obj.Time]=CCG(times,ones(size(times)),...
                        'duration', duration,...
                        'binSize', binsize,...
                        'Fs',1/30000,...
                        'normtype', 'count');
                    catch
                    end
                end
            end
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
            idx=t>.040&t>.200;
            idx2=mean(mat(:,idx),2)<count;
            obj.Count=mat(idx2,:);
        end
        function obj=getACGWithCountBiggerThan(obj, count)
            mat=obj.Count;
            t=obj.Time;
            idx=t>.040&t>.300;
            idx2=mean(mat(:,idx),2)>=count;
            obj.Count=mat(idx2,:);
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
        function [count, t] = getCount(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            count=obj.Count;
            t=obj.Time;
        end
        function [theta]=plot(obj)
            try close(1); catch, end; figure(1);
            mat=obj.Count;
            thetaMod= obj.getThetaModulations;
            t_mag=thetaMod.getThetaModulationMagnitudes;
            t_freq=thetaMod.getThetaFrequency;
%             [t_mag,ind]=sort(t_mag,'ascend');
%                       t_freq=t_freq(ind);

            [t_freq,ind]=sort(t_freq,'descend');
            t_mag=t_mag(ind);
            %             [~,idx]=sort(mean(mat,2));

            mat=mat(ind,:);
            peak=double(1)./t_freq;
            mat=imgaussfilt(mat,.5);
            imagesc(obj.Time,1:size(mat,1),mat)
            ax=gca;
            ax.CLim=[.7 1.2];
            colormap('pink');
            popmean=mean(mat)*size(mat,1)/5;
            new_t=min(obj.Time):.001:max(obj.Time);
            popmean=interp1(obj.Time,popmean,new_t,'spline');
            hold on;
            s1=scatter(peak,1:size(mat,1),15);
            s1.MarkerEdgeColor='#0072BD';
            s2=scatter(2*peak,1:size(mat,1),10);
            t_interest=new_t>.05&new_t<.200;
            [pks,locs] =findpeaks(popmean(:,t_interest),new_t(t_interest),'NPeaks',1);
            p=plot(new_t,popmean);
            p.LineWidth=2;
            p.Color='#A2142F';
            ax.YDir='normal';
            freq=1/locs(1);
            s3=scatter([-locs locs],[pks pks],'v','filled','MarkerFaceColor','#A2142F');
            t=text(-locs,pks,sprintf('%.2fHz',freq),'VerticalAlignment','bottom','HorizontalAlignment','center');
            t.FontSize=12;
            t.FontWeight='bold';
            t.Color='#A2142F';
            units_interest=1:numel(t_freq);
            mean_inter_freq=t_freq(units_interest);
            mean_inter_peak=peak(units_interest);
            treq_mean=mean(mean_inter_freq);
            treq_mean_peak=mean(mean_inter_peak);            
            eb=errorbar(treq_mean_peak,numel(t_freq)/2,std(mean_inter_peak)/sqrt(numel(mean_inter_peak)),'horizontal');
            eb.Color=s1.MarkerEdgeColor;
            eb.LineWidth=2;
            t2=text(treq_mean_peak,numel(t_freq)/2,sprintf('%.2fHz',treq_mean),'VerticalAlignment','bottom','HorizontalAlignment','right');
            t2.Color=eb.Color;
            t2.FontSize=12;
            t2.FontWeight='bold';
            theta.freq=t_freq;
            theta.cum_freq_peak=freq;
        end
    end
end

