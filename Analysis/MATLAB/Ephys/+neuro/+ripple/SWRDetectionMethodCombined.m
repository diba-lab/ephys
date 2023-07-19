classdef SWRDetectionMethodCombined < neuro.ripple.SWRDetectionMethod
    %SWRDETECTIONMETHODRIPPLEONLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SWRDetectionMethodCombined(basepath)
            obj@neuro.ripple.SWRDetectionMethod(basepath)
        end
        
        function rippleFinalCombined = execute(obj)
            conf=obj.Configuration;
            cachefile=fullfile(obj.BasePath,'cacheripple',strcat('Combined_',DataHash(conf),'.mat'));
            try
                load(cachefile,'rippleFinalCombined');
            catch
                probe=obj.getProbe;
                methodRip=neuro.ripple.SWRDetectionMethodRippleOnly(obj.BasePath);
                shanks_rip=str2double(conf.shanks_ripple);
                for ishank=1:numel(shanks_rip)
                    ashank_rip=shanks_rip(ishank);
                    chansofShank_rip=probe.getShank(ashank_rip).getActiveChannels;
                    chansofShank_rip_sel=unique(round(linspace(min(chansofShank_rip),max(chansofShank_rip),32)));
                    ripple=methodRip.execute(chansofShank_rip_sel);
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
                rippleCombinedROnly.saveEventsNeuroscope(obj.BasePath,'RPO');
                methodSW=neuro.ripple.SWRDetectionMethodSWR(obj.BasePath);
                shanks_sw=str2double(conf.shanks_sw);
                for ishank=1:numel(shanks_sw)
                    ashank_sw=shanks_sw(ishank);
                    subfield=['shank' num2str(ashank_sw)];
                    if ~isfield(conf,subfield)
                        % NEUROSCOPE
                        chansofShank_sw=probe.getShank(ashank_sw).getActiveChannels;
                        chansofShank_sw= round(linspace(min(chansofShank_sw),max(chansofShank_sw),17));
                    else
                        chansofShank_sw=str2double(conf.(subfield))'+1;
                    end
                    ripple=methodSW.execute(chansofShank_sw);
                    try
                        rippleCombinedSW=rippleCombinedSW+ripple;
                        display(rippleCombinedSW);
                    catch
                        rippleCombinedSW=ripple;
                    end
                    
                end
                rippleCombinedSW.saveEventsNeuroscope(obj.BasePath,'SWR')
                rippleFinalCombined=rippleCombinedROnly+rippleCombinedSW;
                rippleFinalCombined=rippleFinalCombined.mergeOverlappingRipples;
                save(cachefile,'rippleFinalCombined');
                rippleFinalCombined.saveEventsNeuroscope(obj.BasePath,'CMB')
            end
        end
        function probe=getProbe(obj)
            try
                probe=neuro.probe.Probe(obj.BasePath);
            catch
                fprintf('No Probe File at: %s',obj.BasePath);
            end
            
        end
    end
end

