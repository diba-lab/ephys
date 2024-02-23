classdef (Abstract) NeuroscopeLayout
    %NEUROSCOPELAYOUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    methods (Abstract)
        getSiteSpatialLayout(obj)
    end
    
    methods
        function obj = NeuroscopeLayout()
            %NEUROSCOPELAYOUT Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        
        function [] = getNeuroscopeFileLayout(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            T=obj.getSiteSpatialLayout;

            for ichan=1:numel(T.ChannelNumberComingOutPreAmp)
                if mod(ichan-1,32)==0
                    fprintf('   </group>\n');
                    fprintf('   <group>\n');
                end

                thechan=T.ChannelNumberComingOutPreAmp(ichan);
                fprintf('    <channel skip="0">%d</channel>\n',thechan-1);
                %     fprintf('        %d,\n',thechan+128);
            end
            for ichan=1:numel(T.ChannelNumberComingOutPreAmp)
                if mod(ichan-1,32)==0
                    fprintf('   </group>\n');
                    fprintf('   <group>\n');
                end

                thechan=T.ChannelNumberComingOutPreAmp(ichan);
                fprintf('    <channel skip="0">%d</channel>\n',thechan-1+128);
                %     fprintf('        %d,\n',thechan+128);
            end
        end
        function chanCoords = getChanCoords(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            T=obj.getSiteSpatialLayout;
            t1=T(T.isActive==1,:);
            chanCoords.x = t1.X;  % Setting x-position to zero
            chanCoords.y = t1.Z; % Assigning negative depth values,
        end
        function chanCoords = saveChanCoords(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            chanCoords=obj.getChanCoords;  % Setting x-position to zero
            saveStruct(chanCoords,'channelInfo','basepath',fileparts(obj.getSource));
        end
    end
end

