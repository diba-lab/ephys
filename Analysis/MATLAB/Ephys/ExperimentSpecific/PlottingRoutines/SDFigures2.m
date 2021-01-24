classdef SDFigures2 <Singleton
    %FIGURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Sessions
    end
    
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function obj = SDFigures2()
            % Initialise your custom properties.
            sf=SessionFactory;
            obj.Sessions= sf.getSessions();
        end
    end
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = SDFigures2();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        function plotSWRRate(obj)
            sf=SessionFactory;
            tses=sf.getSessionsTable('AA',1);
            sde=SDExperiment.instance.get;
            cacheFile=fullfile(sde.FileLocations.General.PlotFolder,'Cache',strcat(DataHash(tses),'.mat'));
            conditions=unique(tses.Condition)
            if ~isfile(cacheFile)
                
                for icond=1:numel(conditions)
                    cond=conditions{icond};
                    tses_cond=sf.getSessionsTable(cond,'AA',1);
    
                    clear Ns ts Ns_adj;
                    
                    for isession=1:height(tses_cond)
                        
                        file=tses_cond(isession,:).Filepath;
                        file=file{:};
                        sdd=StateDetectionData(file);
                        sdd_block=sdd.getWindow(timeWindow);
                        ss=sdd.getStateSeries;
                        S.SlidingWindowSizeInSeconds=30*60;
                        S.SlidingWindowLapsInSeconds=30*60;
                        stateRatiosInTime=ss.getStateRatios(seconds(S.SlidingWindowSizeInSeconds)...
                            ,seconds(S.SlidingWindowLapsInSeconds));
                        
                        bc=BuzcodeFactory.getBuzcode(file);
                        ripple=bc.calculateSWR;
                        
                        stateEpisodes=ss.getEpisodes;
                        ripplePeaksInSeconds=ripple.getPeakTimes;
                        ticd=ripple.TimeIntervalCombined;
                        peaktimestampsInSamples=ripplePeaksInSeconds*ticd.getSampleRate;%convert to samples
                        peakTimeStampsAdjustedInSamples=ticd.adjustTimestampsAsIfNotInterrupted(peaktimestampsInSamples);
                        peakTimesAdjustedInSeconds=peakTimeStampsAdjustedInSamples/ticd.getSampleRate;
                        stateNames=ss.getStateNames;
                        clear rippleRates;
                        for istate=1:numel(stateRatiosInTime)
                            
                            thestate=stateRatiosInTime(istate).state;
                            stateRatio=stateRatiosInTime(thestate);
                            try
                                theStateName=stateNames{istate};
                                theEpisode=stateEpisodes.(strcat(theStateName,'state'));
                                idx_all=false(size(ripplePeaksInSeconds));
                                for iepi=1:size(theEpisode,1)
                                    idx_epi=ripplePeaksInSeconds>theEpisode(iepi,1)...
                                        & ripplePeaksInSeconds<theEpisode(iepi,2);
                                    idx_all=idx_all|idx_epi;
                                end
                                stateRipplePeaksInSeconds=ripplePeaksInSeconds(idx_all);
                                [rippleRates(thestate).N,rippleRates(thestate).edges] = histcounts( stateRipplePeaksInSeconds,stateRatio.edges);
                                rippleRates(thestate).state=thestate;
                            catch
                            end
                        end
                        edges=stateRatiosInTime.edges;
                        for istate=1:numel(stateRatiosInTime)
                            thestate=stateRatiosInTime(istate).state;
                            
                            if sum(ismember([1 2 3 5],thestate))
                                Cond(icond).sratio(thestate,:,isession)=stateRatiosInTime(thestate).Ratios;
                                Cond(icond).sCount(thestate,:,isession)=stateRatiosInTime(thestate).N;
                                Cond(icond).rCount(thestate,:,isession)=rippleRates(thestate).N;
                                Cond(icond).edges(thestate,:,isession)=rippleRates(thestate).edges;
                            end
                        end
                    end
                end
                folder=fileparts(cacheFile);
                if ~isfolder(folder), mkdir(folder);end
                save(cacheFile,'Cond');
            else
                load(cacheFile);
            end
            
            
        end
    end
end


