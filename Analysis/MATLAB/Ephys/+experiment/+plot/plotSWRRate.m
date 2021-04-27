filename='/home/mdalam/Downloads/Analysis_code/jahangir-analysis/SessionList.txt';
T_session = readtable(filename, 'Delimiter',',');
indSD=ismember(T_session.SLEEP,'SD');
tsd=T_session(indSD,:);
conditions=unique(tsd.INJECTION);

filename='/home/mdalam/Downloads/Analysis_code/jahangir-analysis/MarkerList.txt';
T_marker = readtable(filename, 'Delimiter',',');
filename='/home/mdalam/Downloads/Analysis_code/jahangir-analysis/BlockList.txt';
T_block = readtable(filename, 'Delimiter',',');


colors= linspecer(numel(conditions),'qualitative');
winInMins=30;
sessionLengthHours=7.5;
windowInSeconds=seconds(minutes(winInMins));
clear p2 mean_Ns ts Cond
try close(7);catch; end; f=figure(7);
f.Units='normalized';    f.Position=[2 .5 .5 .5];
cacheFile=fullfile('/home/mdalam/Downloads/Analysis_code/jahangir-analysis','cache',strcat(DataHash(tsd),'.mat'));
if ~isfile(cacheFile)
    
    for icond=1:numel(conditions)
        indCond=ismember(tsd.INJECTION, conditions{icond});
        tCond=tsd(indCond,:);
        clear Ns ts Ns_adj;
        minsize=inf;
        
        for isession=1:height(tCond)
            
            file=tCond(isession,:).PATH;
            file=file{:};
            sdd=StateDetectionData(file);
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
                    stateRipplePeaksInSeconds=ripplePeaksInSeconds;
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
Figures.plot_RippleRatesInBlocks_StatesSeparated(Cond)
Figures.plot_RippleRatesInBlocks_StatesCombined(Cond)

%%
% Filebase='/run/media/mdalam/Ext_HDD/RatN/RatNd1_ROL_SD/experiment3/recording1/continuous/continuous';
% Channels=[109,98,110,97,111,96,108,99,107,100,106,101,105,102,104,103];
% detected_swr = detect_swr( Filebase, Channels);
