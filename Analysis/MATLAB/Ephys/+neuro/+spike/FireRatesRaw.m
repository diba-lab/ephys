classdef FireRatesRaw
    %FIRERATESRAW Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Data
        ChannelNames
        ClusterInfo
        Info
        SampleRate
    end

    methods
        function obj = FireRatesRaw(data,channelNames,info)
            %FIRERATESRAW Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                obj.Data=data;
                obj.ChannelNames=channelNames;
            end
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
    end
end

