classdef CurrentSourceDensity
    %CURRENTSOURCEDENSITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Data
        Parent
    end
    
    methods
        function obj = CurrentSourceDensity(csd,parent)
            %CURRENTSOURCEDENSITY Construct an instance of this class
            %   Detailed explanation goes here
            obj.Data = csd;
            obj.Parent=parent;
        end
        
        function [] = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ctd=obj.Parent;
            CSD=obj.Data;
            cmax = max(max(CSD));
            time=seconds(ctd.time.getTimePointsZT);
            contourf(time,linspace(1,size(CSD,1)+2,size(CSD,1)),...
                -CSD,40,'LineColor','none');hold on;
            colormap jet; clim([-cmax cmax]);
            set(gca,'YDir','reverse');xlabel('time (s)');ylabel('channel');title(CSD);
            ctd.plot;
            ax=gca;
            ax.YTick=1:numel(ctd.channels);
            ax.YTickLabel=ctd.channels;
        end
    end
end

