classdef StateSeries
    %STATESERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ts
    end
    
    methods
        function obj = StateSeries(ts)
            obj.ts=ts;
        end
        
        function ts = getResampled(obj,newnumpoints)
            ts1=obj.ts;
            time=linspace(ts.Time(1),ts.Time(end),newnumpoints);
            
            ts=ts1.resample(time,'zoh');
        end
        function [] = plot(obj,colorMap)
            ts=obj.ts;hold on;
            num=1;
            for ikey=colorMap.keys
                tempts=ts;
                key=ikey{1};
                tempts.Data(tempts.Data~=key)=nan;
                tempts.Data(tempts.Data==key)=num;num=num+1;
                p1=plot(tempts);
                p1.Color=colorMap(key);
                p1.LineWidth=20;
             
            end
            ax=gca;
            ax.XLim=[tempts.Time(1) tempts.Time(end)];
            ax.YLim=[0 num];
            ax.Color='none';
            ax.Visible='off';
            ax.YDir='reverse';
        end
    end
end

