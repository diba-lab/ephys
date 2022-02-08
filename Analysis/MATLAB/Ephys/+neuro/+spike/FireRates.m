classdef FireRates
    %FIRERATES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Data
        Time
        ChannelNames
        ClusterInfo
        Info
    end
    
    methods
        function obj = FireRates(Data,ChannelNames,Time)
            %FIRERATES Construct an instance of this class
            %   Detailed explanation goes here
            obj.Data=Data;
            obj.ChannelNames=ChannelNames;
            obj.Time=Time;
        end
        
        function [cb]=plotFireRates(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t=hours(seconds(obj.Time.getTimePointsInSec("08:00")));
            
            ch=1:numel(obj.ChannelNames);
            [~,idx1]=sort(mean(obj.Data,2));
            obj=obj.sort(idx1);
            imagesc(t,ch,log10(obj.Data));
            xlabel('ZT (Hrs)')
%             colorMap1 = [linspace(0,1,256)', zeros(256,2)];
            cb=colorbar('Location','manual');
            cb.Position=[.94 .3 .01 .4];
            cb.Label.String='Log Fire Rate (Hz)';
            colormap('hot');
        end
        function obj=get(obj,varargin)
            if islogical(varargin{1})
                tbl=obj.ClusterInfo;
                obj.ClusterInfo=tbl(varargin{1},:);
                data=obj.Data;
                idx=ismember(obj.ChannelNames, obj.ClusterInfo.id);
                obj.Data=data(idx,:);
                chnames=obj.ChannelNames;
                obj.ChannelNames=chnames(idx);
            end
        end
        function obj=sort(obj,varargin)
            if isnumeric(varargin{1})
                data=obj.Data;
                idx=varargin{1};
                obj.Data=data(idx,:);
                chnames=obj.ChannelNames;
                obj.ChannelNames=chnames(idx);
            end
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
        function tblall = getPairwiseCorrelation(obj,windowLength,shift)
            pair=nchoosek(1:size(obj.Data,1),2);
            time=0:obj.Time.SampleRate*shift:obj.Time.getNumberOfPoints;
            for itime=1:(numel(time))-1
                times=time(itime)+1;
                timee=time(itime)+windowLength*obj.Time.SampleRate;
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
                    tbl1.time(:,1:2)=repmat([times-1 timee]/obj.Time.SampleRate,[height(tbl1) 1]);
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

