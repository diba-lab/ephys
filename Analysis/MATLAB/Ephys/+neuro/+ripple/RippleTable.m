classdef RippleTable
    %RIPPLETABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Table
    end
    
    methods
        function obj = RippleTable(table)
            %RIPPLETABLE Construct an instance of this class
            %   Detailed explanation goes here
            obj.Table = table;
        end
        
        function sess = getSessions(obj)
            sess = unique(obj.Table.Session);
        end
        function obj = getSession(obj,sesno)
            obj.Table=obj.Table(obj.Table.Session==sesno,:);
        end
        function obj = getTimeWindow(obj,tw)
            obj.Table=obj.Table(obj.Table.peak>tw(1)&obj.Table.peak<tw(2),:);
        end
        function obj = removeArtifacts(obj)
            obj.Table=obj.Table( ...
                ~(obj.Table.frequency_wavelet==max(obj.Table.frequency_wavelet)|...
                obj.Table.frequency_wavelet==min(obj.Table.frequency_wavelet))...
                ,:);
        end
        function obj = plotScatter(obj,y,sz)
            x=hours(obj.Table.peak);
            y=obj.Table.(y);
            size=obj.Table.(sz);
            scatter(x,y,size/10,"filled",MarkerFaceAlpha=.2);

        end
        function obj = plotRunningAverage(obj,y,winrange,winsize,winstep)
            [y,x]=obj.getRunningAverage(y,winrange,winsize,winstep);
            plot(x,y);
        end
        function [y1,x] = getRunningAverage(obj,y,winrange,winsize,winstep)
            winranger=hours(round(hours(winrange)*20)/20);
            winstart=winranger(1):winstep:(winranger(2)-winsize);
            winstop=winstart+winsize;
            wincenter=winstart+winsize/2;
            x=hours(wincenter);
            y1=nan(size(x));
            for iw=1:numel(wincenter)
                win=[winstart(iw) winstop(iw)];
                w1=obj.getTimeWindow(win);
                y1(iw)=mean(w1.Table.(y));
            end
            plot(x,y1)
        end
        
    end
end

