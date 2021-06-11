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
                times=seconds(sample.getDuration);
                [obj.Count(isu,:),obj.Time]=CCG(times,ones(size(times)),...
                    'duration', duration,...
                    'binSize', binsize,...
                    'Fs',1/30000,...
                    'normtype', 'count');
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
            idx=t>.040&t>.200;
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
        function []=plot(obj)
            try close(1); catch, end; figure(1);
            mat=obj.Count;
            thetaMod= obj.getThetaModulations;
            t_mag=thetaMod.getThetaModulationMagnitudes;
%             t_freq=thetaMod.getThetaFrequency;
            [t_mag1,ind]=sort(t_mag,'descend');
%             [t_mag1,ind]=sort(t_freq,'descend');
%             [~,idx]=sort(mean(mat,2));
            mat=mat(ind,:);
            mat=imgaussfilt(mat,.5);
            imagesc(obj.Time,1:size(mat,1),mat)
            ax=gca;
            ax.CLim=[.7 1.2];
            colormap('pink');
            popmean=mean(mat)*size(mat,1)/5;
            hold on;
            p=plot(obj.Time,popmean);
            p.LineWidth=2;
            p.Color='r';
            ax.YDir='normal';
        end
    end
end

