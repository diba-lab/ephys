classdef FireRatesFilter< neuro.spike.FireRates
    %FIRERATESFILTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = FireRatesFilter(fr)
            %FIRERATESFILTER Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@neuro.spike.FireRates(fr.Data,fr.ChannelNames,fr.Time);
            obj.ClusterInfo=fr.ClusterInfo;
            obj.Info=fr.Info;
        end
        
        function obj = getRatioFilter(obj,windowInsec,slide,ratio)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            frs=obj.Data;
            mfrs=mean(frs,2)*ratio;
            numPointsWindow=windowInsec/obj.Info.TimebinInSec;
            numPointsSlide=slide/obj.Info.TimebinInSec;
            for iwindow=1:ceil((size(frs,2)-numPointsWindow+numPointsSlide)/numPointsSlide)
                start=(iwindow-1)*numPointsSlide+1;
                stop=start+numPointsWindow-1;
                if stop>size(frs,2)
                    stop=size(frs,2);
                end
                win(:,iwindow)=mean(frs(:,start:stop),2);
            end
            idx=sum(win<mfrs,2)>0;
            obj.Data(idx,:)=[];
            obj.ClusterInfo(idx,:)=[];
            obj.ChannelNames(idx)=[];
        end
    end
end

