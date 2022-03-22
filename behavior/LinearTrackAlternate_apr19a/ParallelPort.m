classdef ParallelPort
    %PARALLELPORT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        address
        length
    end
    
    methods
        function obj = ParallelPort()
            %PARALLELPORT Construct an instance of this class
            %   Detailed explanation goes here
            config=readstruct('config.xml');
            obj.address = config.port.address;
            obj.length=config.marker.lengthMS;
            config_io;
        end
        
        function ret = send(obj,num,duration)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            if isstring(num)||ischar(num)
                num=bin2dec(num);
            end      
            if ~exist('duration','var')
                duration=obj.length/1000;
            end
            outp(obj.address,num);
            ret=WaitSecs('UntilTime', GetSecs+duration);
            outp(obj.address,0);
            
        end
    end
end

