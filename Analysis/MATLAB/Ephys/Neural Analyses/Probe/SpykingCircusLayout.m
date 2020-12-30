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
            T=T(T.isActive==1,:);
            for ichan=1:numel(T.ChannelNumberComingOutPreAmp)
                thechan=T(ichan,:);
                if thechan.ChannelNumberComingOutPreAmp<=128+128
                    fprintf(' %d: [%.1f, %.1f],\n',...
                        ichan-1, thechan.X,max(T.Z)-thechan.Z );
                end
            end
        end
    end
end

