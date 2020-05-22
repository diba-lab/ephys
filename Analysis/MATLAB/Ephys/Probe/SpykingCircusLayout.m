classdef (Abstract) SpykingCircusLayout
    %NEUROSCOPELAYOUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    methods (Abstract)
        getSiteSpatialLayout(obj)
    end
    
    methods        
        function [] = getSpykingCircusLayout(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            T=obj.getSiteSpatialLayout;
            
            for ichan=1:numel(T.ChannelNumberComingOutPreAmp)
                thechan=T(ichan,:);
                if thechan.ChannelNumberComingOutPreAmp<129
                    probeaddition=0;
                else
                    probeaddition=400*4;
                end
                if thechan.ChannelNumberComingOutPreAmp<=128+128
                    fprintf(' %d: [%.1f, %.1f],\n',...
                        thechan.ChannelNumberComingOutPreAmp-1, 1550-thechan.X,...
                        3115-(thechan.Z + (thechan.ShankNumber-1) * 400 + probeaddition));
                end
            end
        end
    end
end

