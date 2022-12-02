classdef HVSSWR
    %HVSSWR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        HVS
        SWR
        Time
    end
    
    methods
        function obj = HVSSWR(HVS,SWR)
            %HVSSWR Construct an instance of this class
            %   Detailed explanation goes here
            obj.HVS =HVS;
            obj.SWR=SWR;
            obj.Time=SWR.TimeIntervalCombined;
        end
        
        function plot(obj,color)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~exist('color','var')
                color=[0 0 0];
            end
            hold on
            tw=obj.HVS.TimeWindows;
            ticd=obj.SWR.TimeIntervalCombined;
            ztshift=ticd.getStartTime-ticd.getZeitgeberTime;
            tws=neuro.time.TimeWindowsDuration(...
                seconds(ticd.adjustTimestampsAsIfNotInterrupted(seconds(table2array(...
                tw.getTimeTable))*ticd.getSampleRate)/ticd.getSampleRate)...
                +ztshift);
            obj.SWR.plotHistCount(120,[0 0 0]);
            ax=gca;ax.YLim=[0 2];ax.XLim=[-3 10];ax.YLabel.String='SWR Rate /sec';ax.XLabel.String='ZT (hrs)';
            yyaxis right;ax=gca;ax.YTickLabel=[];
            tws.plotScatter(gca,color);ax.YLim=[-1 1];
            hold off
        end
    end
end

