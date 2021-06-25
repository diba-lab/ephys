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
        
        function plotFireRates(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t=hours(seconds(obj.Time.getTimePointsInSec("08:00")));
            
            ch=1:numel(obj.ChannelNames);
            imagesc(t,ch,log10(obj.Data));
            xlabel('Time (h, 0 = 8 pm)')
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
        
    end
end

