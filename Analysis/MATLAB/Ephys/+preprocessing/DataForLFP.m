classdef DataForLFP
    %DATAFORCLUSTERING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        AnalysisFile
        EventsFile
        Probe
        DataFile
        TimeIntervalCombined
        AnalysisParameters
        Session
    end
    
    methods
        function obj = DataForLFP(dataFile)
            %DATAFORCLUSTERING Construct an instance of this class
            %   TODO 
            % (1) Create required .mat files for Buzcode.
            % (2)
            sde=experiment.SDExperiment.instance.get;
            obj.DataFile = dataFile;
            obj.Session=experiment.Session(fileparts(dataFile));
            [baseFolder,name,ext]=fileparts(dataFile);
            analysisFile=fullfile(baseFolder,sde.FileLocations.Session.Analysis);
            obj.AnalysisFile=analysisFile;
            if isfile(analysisFile)
                S=readstruct(analysisFile);
            else
                l=logging.Logger.getLogger;
                l.error(sprintf('Couldnt read the file %s',analysisFile));
                %% State
                % NEUROSCOPE!
                S.StateDetection.Channels.ThetaChannels=[2,7,12,16,20,25,30,32,34,39,44,48,52,57,62,64,66,71,76,80,84,89,94,96,98,103,108,112,116,121,126,128]-1;
                S.StateDetection.Channels.SWChannels=[2,7,12,16,20,25,30,32,34,39,44,48,52,57,62,64,66,71,76,80,84,89,94,96,98,103,108,112,116,121,126,128]-1;
                S.StateDetection.Channels.BestTheta=nan;
                S.StateDetection.Channels.BestSW=nan;
                S.StateDetection.Channels.EMGChannel=[0 31 96 127];
                S.StateDetection.Overwrite=0;
                S.StateDetection.HVSFilter=0;
                %% Ripple
                S.Ripple.RippleOnly.SomeParameters='';
                S.Ripple.SWR.SomeParameters='';
                S.Ripple.Combined.SomeParameters='';
                %% Power
                S.Power.Channel='';
                
                %% Current Source Density
                S.CSD.SomeParameter='';
                
                %% HVS
                S.HVS.Channel=nan;
                S.HVS.HVSThresholdSD=nan;
                S.HVS.ChannelHC=nan;
                S.HVS.MinimumInterEventIntervalInSec=nan;
                S.HVS.FrequencyTheta=[nan nan];
                S.HVS.ThresholdZScoreTheta=nan;
                S.HVS.FrequencyAboveTheta=[nan nan];
                S.HVS.ThresholdZScoreAboveTheta=nan;
                writestruct(S,analysisFile);
            end
            obj.EventsFile=fullfile(baseFolder,sde.FileLocations.Session.Events);
%             try
%                 S=readstruct(obj.EventsFile);
%             catch
%                 S=[];
%                 S.HVS='HVS';
%                 S.SWR='SWR';
%                 writestruct(S, obj.EventsFile);
%             end
% 
            obj.AnalysisParameters=S;
        end
        
        function obj = setProbe(obj,probe)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Probe = probe;
        end
        function obj = setTimeIntervalCombined(obj,ticd)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.TimeIntervalCombined = ticd;
        end
        function ctd = getChannelTimeDataHard(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            [folder,name,ext]=fileparts(obj.DataFile);
            ctd=neuro.basic.ChannelTimeDataHard(folder);
        end
        function bad = getBad(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            folder=fileparts(obj.DataFile);
            sde=experiment.SDExperiment.instance.get;
            try
                badfile=fullfile(folder, sde.FileLocations.Preprocess.Bad);
                bad=readtable(badfile, 'Delimiter',',');
            catch
                l=logging.Logger.getLogger;
                l.error('No Bad file: %s\n',badfile)
                bad=[];
            end
        end
        
        function sdd = getStateDetectionData(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %%
            [folder, name, ext]=fileparts(obj.DataFile);
            baseFolder=convertStringsToChars(folder);
            params=obj.AnalysisParameters.StateDetection;
            
            bad=obj.getBad();
            params.bad=[bad.Start bad.Stop];
            bcs=buzcode.BuzcodeStructure(baseFolder);
            sdd=bcs.detectStates(params);
            S=obj.AnalysisParameters;
            S.StateDetection.Channels.BestTheta=sdd.getThetaChannelID;
            S.StateDetection.Channels.BestSW=sdd.getSWChannelID;
            obj.setAnalysisParameters(S);
            
        end
        function ripples = getRippleEvents(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO
            basefolder=fileparts(obj.DataFile);
            bc=buzcode.BuzcodeFactory.getBuzcode(basefolder);
            ripples=bc.calculateSWR;
            ripples.saveEventsNeuroscope;
        end
        function obj = setAnalysisParameters(obj,S)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO
            writestruct(S,obj.AnalysisFile);
            obj.AnalysisParameters=S;
        end
        function params = getAnalysisParameters(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO
            params=obj.AnalysisParameters;
        end
    end
end

