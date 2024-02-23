classdef FireRates < neuro.spike.FireRatesRaw
    %FIRERATES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Time
    end
    
    methods
        function obj = FireRates(Data,ChannelNames,Time)
            %FIRERATES Construct an instance of this class
            %   Detailed explanation goes here
            obj.Data=Data;
            obj.ChannelNames=ChannelNames;
            obj.Time=Time;
        end
        
        function [axs]=plotFireRates(obj,axs)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~exist('axs','var')
                tiledlayout(5,1)
                ax1=nexttile(1,[3 1]);hold on;
            else
                axes(axs(1));ax1=gca;
            end
            til=obj.Time.getTimeIntervalList;
            ax1.Color='k';
            st=1;
            for iti=1:til.length
                ti=til.get(iti);
                t=minutes(ti.getTimePointsZT);

                ch=1:numel(obj.ChannelNames);
                [~,idx1]=sort(mean(obj.Data,2));
                obj=obj.sort(idx1);
                imagesc(t,ch,obj.Data(:,st:(st+ti.getNumberOfPoints-1)));hold on
                st=st+ti.getNumberOfPoints;
            end
            ax1.YLim=[min(ch) max(ch)+1]-.5;
            ax1.CLim=[0 5];
            xlabel('ZT (min)')
            cb=colorbar('Location','south');
            cb.Position(3)=cb.Position(3)/5;
            cb.Label.String='Log Fire Rate (Hz)';
            cb.Color='w';
            colormap('hot');
            ax1.YDir="normal";
            hold on
            t1=minutes(obj.Time.getTimePointsZT);
            data=mean(obj.Data);

            data2=ft_preproc_lowpassfilter(data,1/obj.Info.TimebinInSec,1/10);
            if ~exist('axs','var')
                ax2=nexttile(4);
            else
                axes(axs(2));ax2=gca;
            end
            plot(t1,data2);

            data1=ft_preproc_highpassfilter(data,1/obj.Info.TimebinInSec,1/6);
            if ~exist('axs','var')
                ax3=nexttile(5);
            else
                axes(axs(3));ax3=gca;
            end
            plot(t1,data1);
            yline(.3);

            linkaxes([ax1 ax2 ax3],'x');
        end
        function obj = getWindow(obj,window)
            t=obj.Time;
            if isduration(window)
                window=t.getDatetime(window);
                tnew=t.getTimeIntervalForTimes(window);
            end
            obj.Time=tnew;
            window_samples=t.getSampleForClosest(window);
            obj.Data=obj.Data(:,window_samples(1):window_samples(2));
        end
        function obj = getFilteredGaussian(obj,windowsec)
            t=obj.Time;
            sr=t.getSampleRate;
            winsample=windowsec*sr;
            obj.Data=smoothdata(obj.Data,2,"gaussian",winsample);
        end
        function tblall = getPairwiseCorrelation(obj,windowLength,shift)
            pair=nchoosek(1:size(obj.Data,1),2);
            time=0:obj.Time.getSampleRate*shift:obj.Time.getNumberOfPoints;
            for itime=1:(numel(time))-1
                times=time(itime)+1;
                timee=time(itime)+windowLength*obj.Time.getSampleRate;
                idx=times: timee;
                if idx(end)<=size(obj.Data,2)
                    data1=obj.Data(:,idx)';
                    r1=corrcoef(data1,'Rows','pairwise');
                    for ipair=1:size(pair,1)
                        R(ipair,1)=r1(pair(ipair,1),pair(ipair,2));
                    end
                    pairNo1=1:size(pair,1);
                    pairNo=pairNo1';
                    tbl1=table(pairNo,pair,R);
                    tbl1.timeNo(:,1)=itime;
                    tbl1.time(:,1:2)=repmat([times-1 timee]/ ...
                        obj.Time.getSampleRate,[height(tbl1) 1]);
                    if itime==1
                        tblall=tbl1;
                    else
                        tblall=[tblall; tbl1];
                    end
                end
            end
        end
        
    end
end

