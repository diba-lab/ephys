classdef SWRDetectionMethodSWR < SWRDetectionMethod
    %SWRDETECTIONMETHODRIPPLEONLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SWRDetectionMethodSWR(basepath)
            %SWRDETECTIONMETHODRIPPLEONLY Construct an instance of this class
            %   Detailed explanation goes here
            
            obj@SWRDetectionMethod(basepath)
        end
        
        function ripple1 = execute(obj)
            conf=obj.Configuration;
            chans=str2double( conf.channnels);
            list1=dir(fullfile(obj.BasePath,'*.xml'));
            str=DataHash(conf);
            cacheFileName=fullfile(obj.BasePath,'cache',[str '.mat']);
            [folder,~,~]=fileparts(cacheFileName);if ~isfolder(folder), mkdir(folder); end
            if ~exist(cacheFileName,'file')
                ripple=detect_swr(fullfile(list1.folder,list1.name),chans,[]...
                    ,'EVENTFILE',str2double( conf.eventfile)...
                    ,'FIGS',str2double( conf.figs)...
                    ,'swBP',str2double( conf.swbp)...
                    ,'ripBP',str2double( conf.ripbp)...
                    ,'WinSize',str2double( conf.winsize)...
                    ,'Ns_chk',str2double( conf.ns_chk)...
                    ,'thresSDswD',str2double( conf.thressdswd)...
                    ,'thresSDrip',str2double( conf.thressdrip)...
                    ,'minIsi',str2double( conf.minisi)...
                    ,'minDurSW',str2double( conf.mindursw)...
                    ,'maxDurSW',str2double( conf.maxdursw)...
                    ,'minDurRP',str2double( conf.mindurrp)...
                    ,'DEBUG',str2double( conf.debug)...
                    );
                save(cacheFileName,'ripple');
            else
                S=load(cacheFileName);
                fnames=fieldnames(S);
                ripple=S.(fnames{1});
            end
            ripple1=SWRipple(ripple);
        end
    end
end

