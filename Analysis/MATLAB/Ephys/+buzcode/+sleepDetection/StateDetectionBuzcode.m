classdef StateDetectionBuzcode < neuro.state.State.StateDetectionMethod
    %SLEEPDETECTIONBUZCODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        %   basePath        folder containing .xml and .lfp files.
        %                   basePath and files should be of the form:
        %                   'whateverfolder/recordingName/recordingName'
        %   (optional)      If no inputs included, select folder(s) containing .lfp
        %                   and .xml file in prompt.
        %   (optional)      if no .lfp in basePath, option to select multiple
        %                   lfp-containing subfolders
        %
        %   OPTIONS
        overwrite
        %   'overwrite'     Default: false, overwrite all processing steps
        ignoreManual
        %   'ignoreManual'  Default: false. Overwrite manual scoring from TheStateEditor
        savebool
        %   'savebool'      Default: true
        scoretime
        %   'scoretime'     Window of time to score. Default: [0 Inf]
        %                   NOTE: must be continous interval
        ignoretime
        %   'ignoretime'    time intervals winthin score time to ignore
        %                   (for example, opto stimulation or behavior with artifacts)
        winparms
        %   'winparms'      [FFT window , smooth window] (Default: [2 15])
        %                   (Note: updated from [10 10] based on bimodaility optimization, 6/17/19)
        SWWeightsName
        %   'SWWeightsName' Name of file in path (in Dependencies folder)
        %                   containing the weights for the various frequencies to
        %                   be used for SWS detection.  Default is to use Power Spectrum Slope ('PSS'),
        %                   but can also try 'SWweights.mat'
        %                     - For hippocampus-only recordings, enter
        %                     'SWweightsHPC.mat' for this if default doesn't work
        Notch60Hz
        %   'Notch60Hz'     Boolean 0 or 1.  Value of 1 will notch out the 57.5-62.5 Hz
        %                   band, default is 0, no notch.  This can be necessary if
        %                   electrical noise.
        NotchUnder3Hz
        %   'NotchUnder3Hz' Boolean 0 or 1.  Value of 1 will notch out the 0-3 Hz
        %                   band, default is 0, no notch.  This can be necessary
        %                   due to poor grounding and low freq movement transients
        NotchHVS
        %   'NotchHVS'      Boolean 0 or 1.  Value of 1 will notch the 4-10 and
        %                   12-18 Hz bands for SW detection, default is 0, no
        %                   notch.  This can be useful in
        %                   recordings with prominent high voltage spindles which
        %                   have prominent ~16hz harmonics
        NotchTheta
        %   'NotchTheta'    Boolean 0 or 1.  Value of 1 will notch the 4-10 Hz
        %                   band for SW detection, default is 0, no notch.  This
        %                   can be useful to
        %                   transform the cortical spectrum to approximately
        %                   hippocampal, may also be necessary with High Voltage
        %                   Spindles
        stickytrigger
        %   'stickytrigger' Implements a "sticky" trigger for SW/EMG threshold
        %                   crossings: metrics must reach halfway between threshold
        %                   and opposite peak to count as crossing (reduces
        %                   flickering, good for HPC recordings) (default:false)
        SWChannels
        %   'SWChannels'    A vector list of channels that may be chosen for SW
        %                   signal
        ThetaChannels
        %   'ThetaChannels' A vector list of channels that may be chosen for Theta
        %                   signal
        rejectChannels
        %   'rejectChannels' A vector of channels to exclude from the analysis
        saveLFP
        %   'saveLFP'       (default:true) to save SleepScoreLFP.lfp.mat file
        noPrompts
        %   'noPrompts'     (default:false) an option to not prompt user of things
        %
        %OUTPUT
        %   !THIS IS OUT OF DATE - UPDATE!
        %   StateIntervals  structure containing start/end times (seconds) of
        %                   NREM, REM, WAKE states and episodes. states is the
        %                   "raw" state scoring. episodes are joined episodes of
        %                   extended (40s) time in a given states, allowing for
        %                   brief interruptions. also contains NREM packets,
        %                   unitary epochs of NREM as described in Watson et al 2016.
        %                   saved in a .mat file:
        %                   recordingname_SleepScore.mat
        
        EMGFromLFP
        SleepScoreLFP
        SleepScoreMetrics
        StatePlotMaterials
        savedir
        basePath
        %   'savedir'       Default: datasetfolder
        sessionmetadatapath
        bz_sleepstatepath
        recordingname
        timestamps
    end
    properties (Access=public)
        
    end
    
    methods
        function obj = StateDetectionBuzcode(varargin)
            %SLEEPDETECTIONBUZCODE Construct an instance of this class
            %   Detailed explanation goes here
            %% inputParse for Optional Inputs and Defaults
            p = inputParser;
            
            addParameter(p,'overwrite',false)
            addParameter(p,'savebool',true,@islogical)
            addParameter(p,'scoretime',[0 Inf])
            addParameter(p,'ignoretime',[])
            addParameter(p,'SWWeightsName','SWweightsHPC.mat')
            addParameter(p,'Notch60Hz',0)
            addParameter(p,'NotchUnder3Hz',0)
            addParameter(p,'NotchHVS',0)
            addParameter(p,'NotchTheta',0)
            addParameter(p,'SWChannels',0)
            addParameter(p,'ThetaChannels',0)
            addParameter(p,'rejectChannels',[]);
            addParameter(p,'noPrompts',true);
            addParameter(p,'stickytrigger',true);
            addParameter(p,'saveLFP',true);
            addParameter(p,'winparms',[2 15]);
            addParameter(p,'ignoreManual',false)
            
            parse(p,varargin{:})
            %Clean up this junk...
            obj.overwrite = p.Results.overwrite;
            obj.scoretime = p.Results.scoretime;
            obj.ignoretime = p.Results.ignoretime;
            obj.SWWeightsName = p.Results.SWWeightsName;
            obj.Notch60Hz = p.Results.Notch60Hz;
            obj.NotchUnder3Hz = p.Results.NotchUnder3Hz;
            obj.NotchHVS = p.Results.NotchHVS;
            obj.NotchTheta = p.Results.NotchTheta;
            obj.SWChannels = p.Results.SWChannels;
            obj.ThetaChannels = p.Results.ThetaChannels;
            obj.rejectChannels = p.Results.rejectChannels;
            obj.noPrompts = p.Results.noPrompts;
            obj.stickytrigger = p.Results.stickytrigger;
            obj.saveLFP = p.Results.saveLFP;
            obj.winparms = p.Results.winparms;
            obj.ignoreManual = p.Results.ignoreManual; 

        end
        
        
        function stateDetectionData = getStates(obj,varargin)
            
            try update=varargin{1}; catch, update=false; end
            if ~exist(obj.bz_sleepstatepath,'file')||update
                %Use the calculated scoring metrics to divide time into states
                display('Clustering States Based on EMG, SW, and TH LFP channels')
                [ints,idx,MinTimeWindowParms] = ClusterStates_DetermineStates(...
                    obj.SleepScoreMetrics);
                
                %% RECORD PARAMETERS from scoring
                %             detectionparms.userinputs = p.Results;
                detectionparms.MinTimeWindowParms = MinTimeWindowParms;
                detectionparms.SleepScoreMetrics = obj.SleepScoreMetrics;
                
                % note and keep special version of original hists and threshs
                
                SleepState.ints = ints;
                SleepState.idx = idx;
                SleepState.detectorinfo.detectorname = 'SleepScoreMaster';
                SleepState.detectorinfo.detectionparms = detectionparms;
                SleepState.detectorinfo.detectionparms.histsandthreshs_orig = detectionparms.SleepScoreMetrics.histsandthreshs;
                SleepState.detectorinfo.detectiondate = datestr(now,'yyyy-mm-dd');
                SleepState.detectorinfo.StatePlotMaterials = obj.StatePlotMaterials;
                %Saving SleepStates
                %% MAKE THE STATE SCORE OUTPUT FIGURE
                %ClusterStates_MakeFigure(stateintervals,stateIDX,figloc,SleepScoreMetrics,StatePlotMaterials);
                try
                    ClusterStates_MakeFigure(SleepState,obj.basePath,obj.noPrompts);
                    disp('Figures Saved to StateScoreFigures')
                catch
                    disp('Figure making error')
                end
                
                save(obj.bz_sleepstatepath,'SleepState');
            else
                load(obj.bz_sleepstatepath);
            end
            stateDetectionData=StateDetectionData(SleepState,obj.basePath,...
                obj.recordingname,obj.timestamps);
        end
        
        function obj = setBuzcodeStructer(obj,buzcodeStructure)
            obj.savedir=buzcodeStructure.DataSetFolder;
            %% Database File Management
            savefolder = fullfile(obj.savedir,buzcodeStructure.RecordingName);
            if ~exist(savefolder,'dir')
                mkdir(savefolder)
            end
            obj.recordingname=buzcodeStructure.RecordingName;
            obj.timestamps=buzcodeStructure.timestamps;
            %Filenames of metadata and SleepState.states.mat file to save
            obj.sessionmetadatapath = fullfile(savefolder,[buzcodeStructure.RecordingName,'.SessionMetadata.mat']);
            %Buzcode outputs
            obj.bz_sleepstatepath = fullfile(savefolder,[buzcodeStructure.RecordingName,'.SleepState.states.mat']);
            obj.basePath=buzcodeStructure.basePath;
            %% Get channels not to use
            sessionInfo = bz_getSessionInfo(buzcodeStructure.basePath,'noPrompts',obj.noPrompts);
            % check that SW/Theta channels exist in rec..
            if length(obj.SWChannels) > 1
                if sum(ismember(obj.SWChannels,sessionInfo.channels)) ~= length(obj.SWChannels)
                    error('some of the SW input channels dont exist in this recording...?')
                end
            end
            if length(obj.ThetaChannels) > 1
                if sum(ismember(obj.ThetaChannels,sessionInfo.channels)) ~= length(obj.ThetaChannels)
                    error('some of the theta input channels dont exist in this recording...?')
                end
            end
            
            %Is this still needed?/Depreciated?
            % if exist(sessionmetadatapath,'file')%bad channels is an ascii/text file where all lines below the last blank line are assumed to each have a single entry of a number of a bad channel (base 0)
            %     load(sessionmetadatapath)
            %     rejectChannels = [rejectChannels SessionMetadata.ExtracellEphys.BadChannels];
            % elseif isfield(sessionInfo,'badchannels')
            if isfield(sessionInfo,'badchannels')
                obj.rejectChannels = [obj.rejectChannels sessionInfo.badchannels]; %get badchannels from the .xml
            else
                display('No baseName.SessionMetadata.mat, no badchannels in your xml - so no rejected channels')
            end
            obj.EMGFromLFP = obj.getEMGfromLFP();
            obj.SleepScoreLFP = obj.getSLowWaveThetaChannels();
            [obj.SleepScoreMetrics, obj.StatePlotMaterials] = obj.getClusterMetrics();
        end
        function obj=overwriteEMGFromLFP(obj)
            obj.EMGFromLFP=obj.getEMGfromLFP(true);
        end
        function obj=overwriteSleepScoreLFP(obj)
            obj.SleepScoreLFP = obj.getSLowWaveThetaChannels(true);
        end
        function obj=overwriteSleepScoreMetrics(obj)
            [obj.SleepScoreMetrics, obj.StatePlotMaterials] = obj.getClusterMetrics(true);
        end

    end
    methods (Access=private)
        function EMGFromLFP = getEMGfromLFP(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% CALCULATE EMG FROM HIGH-FREQUENCY COHERENCE
            % Load/Calculate EMG based on cross-shank correlations
            % (high frequency correlation signal = high EMG).
            % Schomburg E.W. Neuron 84, 470-485. 2014)
            try overwrite1=varargin{1}; catch, overwrite1=false; end
            EMGFromLFP = bz_EMGFromLFP(obj.basePath,'overwrite',overwrite1,...
                'rejectChannels',obj.rejectChannels,'noPrompts',obj.noPrompts,...
                'saveMat',true);
        end
        
        function SleepScoreLFP = getSLowWaveThetaChannels(obj,varargin)
            %% DETERMINE BEST SLOW WAVE AND THETA CHANNELS
            %Determine the best channels for Slow Wave and Theta separation.
            %Described in Watson et al 2016, with modifications
            try overwrite1=varargin{1}; catch, overwrite1=false; end

            SleepScoreLFP = PickSWTHChannel(obj.basePath,...
                obj.scoretime,obj.SWWeightsName,...
                obj.Notch60Hz,obj.NotchUnder3Hz,obj.NotchHVS,obj.NotchTheta,...
                obj.SWChannels,obj.ThetaChannels,obj.rejectChannels,...
                overwrite1,'ignoretime',obj.ignoretime,...
                'noPrompts',obj.noPrompts,'saveFiles',obj.saveLFP,...
                'window',obj.winparms(1),'smoothfact',obj.winparms(2),'IRASA',true);
        end
        
        function [SleepScoreMetrics,StatePlotMaterials] = getClusterMetrics(obj,varargin)
            %% CLUSTER STATES BASED ON SLOW WAVE, THETA, EMG
            filename=fullfile(obj.basePath, [obj.recordingname '.SleepScoreMetrics.mat']);
            try overwrite1=varargin{1}; catch, overwrite1=false; end
            if ~exist(filename,'file')||overwrite1
                %Calculate the scoring metrics: broadbandLFP, theta, EMG
                display('Quantifying metrics for state scoring');
                [SleepScoreMetrics,StatePlotMaterials] = ClusterStates_GetMetrics(...
                    obj.basePath,obj.SleepScoreLFP,obj.EMGFromLFP,obj.overwrite,...
                    'onSticky',obj.stickytrigger,'ignoretime',obj.ignoretime);
                save(filename,'SleepScoreMetrics','StatePlotMaterials');
            else
                load(filename,'SleepScoreMetrics','StatePlotMaterials');
            end
        end
    end
    methods (Access=public)
        
    end
end

