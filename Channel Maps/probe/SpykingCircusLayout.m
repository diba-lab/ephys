classdef (Abstract) SpykingCircusLayout
    %NEUROSCOPELAYOUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    methods (Abstract)
        getSiteSpatialLayout(obj)
    end
    
    methods
        function obj = SpykingCircusLayout()
            %NEUROSCOPELAYOUT Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        
        function [] = getSpykingCircusLayout(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            T=obj.getSiteSpatialLayout;
            
            for ichan=1:numel(T.ChannelNumberComingOutPreAmp)
                %                 if mod(ichan-1,32)==0
                %                     fprintf('   </group>\n');
                %                     fprintf('   <group>\n');
                %                 end
                
                thechan=T(ichan,:);
                fprintf(' %d: [%.1f, %.1f],\n',...
                    thechan.ChannelNumberComingOutPreAmp-1,thechan.Z,thechan.X);
                %     fprintf('        %d,\n',thechan+128);
            end
            for ichan=1:numel(T.ChannelNumberComingOutPreAmp)
%                 if mod(ichan-1,32)==0
%                     fprintf('   </group>\n');
%                     fprintf('   <group>\n');
%                 end
                
                thechan=T(ichan,:);
                fprintf(' %d: [%.1f, %.1f],\n',...
                    thechan.ChannelNumberComingOutPreAmp-1+128,thechan.Z,thechan.X);
               
            end
        end
    end
end

