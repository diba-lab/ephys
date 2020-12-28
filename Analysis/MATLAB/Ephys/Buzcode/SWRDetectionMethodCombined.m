classdef SWRDetectionMethodCombined < SWRDetectionMethod
    %SWRDETECTIONMETHODRIPPLEONLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SWRDetectionMethodCombined(basepath)
            obj@SWRDetectionMethod(basepath)
        end
        
        function rippleFinalCombined = execute(obj)
            conf=obj.Configuration;
            probe=obj.getProbe;
            
            methodRip=SWRDetectionMethodRippleOnly(obj.BasePath);
            shanks_rip=str2double(conf.shanks_ripple);
            for ishank=1:numel(shanks_rip)
                ashank_rip=shanks_rip(ishank);
                chansofShank_rip=probe.getShank(ashank_rip).getActiveChannels;
                ripple=methodRip.execute(chansofShank_rip);
                try
                    rippleCombinedROnly=rippleCombinedROnly+ripple;
                    display(rippleCombinedROnly)
                catch ME
                    rippleCombinedROnly=ripple;
                end
                % for each shank calculate the ripples
                % (1) by ripple detection
                % (2) by detectSWR function
            end
            rippleCombinedROnly.saveEventsNeuroscope(obj.BasePath);
            methodSW=SWRDetectionMethodSWR(obj.BasePath);
            shanks_sw=str2double(conf.shanks_sw);
            for ishank=1:numel(shanks_sw)
                ashank_sw=shanks_sw(ishank);
                subfield=['shank' num2str(ashank_sw)];
                if ~isfield(conf,subfield)
                    % NEUROSCOPE
                    chansofShank_sw=probe.getShank(ashank_sw).getActiveChannels-1;
                else
                    chansofShank_sw=str2double(conf.(subfield))';
                end
                ripple=methodSW.execute(chansofShank_sw);
                try
                    rippleCombinedSW=rippleCombinedSW+ripple;
                    display(rippleCombinedSW);
                catch
                    rippleCombinedSW=ripple;
                end

            end
            rippleCombinedSW.saveEventsNeuroscope(obj.BasePath)
            rippleFinalCombined=rippleCombinedROnly+rippleCombinedSW;
            rippleFinalCombined.saveEventsNeuroscope(obj.BasePath)
        end
        function probe=getProbe(obj)
            try
                list=dir(fullfile(obj.BasePath,'*Probe*'));
                probe=Probe(fullfile(list.folder,list.name));
            catch
                fprintf('No Probe File at: %s',obj.BasePath);
            end
            
        end
    end
end

