classdef SWRDetectionMethodCombined < SWRDetectionMethod
    %SWRDETECTIONMETHODRIPPLEONLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SWRDetectionMethodCombined(basepath)
            obj@SWRDetectionMethod(basepath)
        end
        
        function ripple1 = execute(obj)
            conf=obj.Configuration;
            basepath=obj.BasePath;
            shanks=str2double(conf.shanks);
            for ishank=1:numel(shanks)
                chansofShank;
                    method1=SWRDetectionMethodRippleOnly(obj.BasePath,chansofShank);
                    method2=SWRDetectionMethodSWR(obj.BasePath,chansofShank);
                    ripple1=ripple1+method1.execute;
                    ripple2=ripple2+method2.execute;
                % for each shank calculate the ripples
                       % (1) by ripple detection
                       % (2) by detectSWR function
            end
            
            % combine the results into one RippleAbs object
        end
    end
end

