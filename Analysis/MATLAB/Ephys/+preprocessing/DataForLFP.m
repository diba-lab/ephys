classdef DataForLFP
    %DATAFORCLUSTERING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        AnalysisFile
        Probe
        DataFile
        TimeIntervalCombined
        AnalysisParameters
    end
    
    methods
        function obj = DataForLFP(dataFile)
            %DATAFORCLUSTERING Construct an instance of this class
            %   TODO 
            % (1) Create required .mat files for Buzcode.
            % (2)
            obj.DataFile = dataFile;
            sde=experiment.SDExperiment.instance.get;
            [baseFolder,name,ext]=fileparts(dataFile);
            analysisFile=fullfile(baseFolder,sde.FileLocations.Session.Analysis);
            obj.AnalysisFile=analysisFile;
            try
                S=readstruct(analysisFile);
            catch
                %% State
                % NEUROSCOPE!
                S.StateDetection.Channels.ThetaChannels=[2,7,12,16,20,25,30,32,34,39,44,48,52,57,62,64,66,71,76,80,84,89,94,96,98,103,108,112,116,121,126,128]-1;
                S.StateDetection.Channels.SWChannels=[2,7,12,16,20,25,30,32,34,39,44,48,52,57,62,64,66,71,76,80,84,89,94,96,98,103,108,112,116,121,126,128]-1;
                S.StateDetection.Channels.BestTheta=nan;
                S.StateDetection.Channels.BestSW=nan;
                S.StateDetection.Channels.EMGChannel=[0 31 96 127];
                S.StateDetection.Overwrite=0;
                %% Ripple
                S.Ripple.RippleOnly.SomeParameters='';
                S.Ripple.SWR.SomeParameters='';
                S.Ripple.Combined.SomeParameters='';
                %% Power
                S.Power.Channel='';
                
                %% Current Source Density
                S.CSD.SomeParameter='';
                writestruct(S,analysisFile);
            end
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
        function ctd = getChannelTimeData(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            [folder,name,ext]=fileparts(obj.DataFile);
            ctd=neuro.basic.ChannelTimeData(folder);
        end
               
        function sdd = getStateDetectionData(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %%
            [folder, name, ext]=fileparts(obj.DataFile);
            baseFolder=convertStringsToChars(folder);
            params=obj.AnalysisParameters.StateDetection;
            sde=SDExperiment.instance.get;
            folder=fileparts(obj.DataFile);
            try
                badfile=fullfile(folder, sde.FileLocations.Preprocess.Bad);
                bad=readstruct(badfile);
            catch
                bad=[];
            end
            params.bad=bad.BadTimes;
            bcs=BuzcodeStructure(baseFolder);
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
            bc=BuzcodeFactory.getBuzcode(basefolder);
            ripples=bc.calculateSWR;
        end
        function tfmap = getPowerSpectrum(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO
            
        end
        function SykingCircusOutputFolder = getCSD(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO
            
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

