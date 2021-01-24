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
            sde=SDExperiment.instance.get;
            [baseFolder,name,ext]=fileparts(dataFile);
            analysisFile=fullfile(baseFolder,sde.FileLocations.Session.Analysis);
            obj.AnalysisFile=analysisFile;
            try
                S=readstruct(analysisFile);
            catch
                %% State
                % NEUROSCOPE!
                S.StateDetection.Channels.ThetaChannels=[11    13    15    17    18    20    22    43    45    47    49    50    52    54    75    77    79    81    82    84    86   107   109   111   113   114   116   118]-1;
                S.StateDetection.Channels.SWChannels=[11    13    15    17    18    20    22    43    45    47    49    50    52    54    75    77    79    81    82    84    86   107   109   111   113   114   116   118]-1;
                S.StateDetection.Channels.BestTheta=nan;
                S.StateDetection.Channels.BestSW=nan;
                S.StateDetection.Channels.EMGChannel=[1 2 3 4];
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
            ctd=ChannelTimeData(folder);
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
        function ripple = getRippleEvents(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% TODO
            
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

