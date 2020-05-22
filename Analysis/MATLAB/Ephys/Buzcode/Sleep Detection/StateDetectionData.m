birsenclassdef StateDetectionData
    %STATEDETECTIONDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    properties (Access=public)
        SleepStateStruct
        StatesSeries
        BasePath
        RecordingName
    end
    
    methods
        function obj = StateDetectionData(sleepStatestruct,basePath,recordingname,ts)
            %STATEDETECTIONDATA Construct an instance of this class
            %   Detailed explanation goes here
            obj.SleepStateStruct=sleepStatestruct;
            obj.BasePath=basePath;
            obj.RecordingName=recordingname;
            ts1=timeseries(sleepStatestruct.idx.states,...
                sleepStatestruct.idx.timestamps,'Name','States');
            ts1.TimeInfo.StartDate=ts.TimeInfo.StartDate;
            obj.StatesSeries=ts1;
        end
        
        function episodes= joinStates(obj)
            %% JOIN STATES INTO EPISODES
            
            % Extract states, Episodes, properly organize params etc, prep for final saving
            display('Calculating/Saving Episodes')
            episodes=StatesToEpisodes(obj.SleepStateStruct,obj.BasePath);
        end
        function []= openStateEditor(obj)
            TheStateEditor([obj.BasePath,filesep,obj.RecordingName])
        end
        function [ss1]= getTimewindow(obj,timeWindow)
            range=obj.getRange(timeWindow);
            
            ss=obj.StatesSeries;
            ss1=timeseries(ss.Data(range),ss.Time(range));
            ss1.TimeInfo.StartDate=ss.TimeInfo.StartDate;
        end
        function ts=getEMG(obj,timeWindow)
            ssm=obj.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics;
            time=double(ssm.t_clus);
            if exist('timeWindow','var')
                range=obj.getRange(timeWindow);
            else
                range=ones(size(ssm.t_clus));
            end
            time=time(range);
            EMG=double(ssm.EMG(range));
            ts=timeseries(EMG,time,'Name','EMG');
            ts.TimeInfo.StartDate=obj.StatesSeries.TimeInfo.StartDate;
            ts.TimeInfo.Format=TimeFactory.getHHMMSS;
        end
        function ts=getEMGThreshold(obj)
            ssm=obj.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.EMGthresh;
        end
        function ts=getEMGSticky(obj)
            ssm=obj.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.stickyEMG;
        end
        function ts=getThetaRatio(obj,timeWindow)
            ssm=obj.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics;
            time=double(ssm.t_clus);
            if exist('timeWindow','var')
                range=obj.getRange(timeWindow);
            else
                range=ones(size(ssm.t_clus));
            end
            time=time(range);
            EMG=double(ssm.thratio(range));
            ts=timeseries(EMG,time,'Name',num2str(ssm.THchanID));
            ts.TimeInfo.StartDate=obj.StatesSeries.TimeInfo.StartDate;
            ts.TimeInfo.Format=TimeFactory.getHHMMSS;
        end
        function ts=getThetaRatioThreshold(obj)
            ssm=obj.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.THthresh;
        end
        function ts=getThetaSticky(obj)
            ssm=obj.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.stickyTH;
        end

        function ts=getSW(obj,timeWindow)
            ssm=obj.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics;
            time=double(ssm.t_clus);
            if exist('timeWindow','var')
                range=obj.getRange(timeWindow);
            else
                range=ones(size(ssm.t_clus));
            end
            time=time(range);
            EMG=double(ssm.broadbandSlowWave(range));
            ts=timeseries(EMG,time,'Name',num2str(ssm.SWchanID));
            ts.TimeInfo.StartDate=obj.StatesSeries.TimeInfo.StartDate;
            ts.TimeInfo.Format=TimeFactory.getHHMMSS;
        end
        function ts=getSWThreshold(obj)
            ssm=obj.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.swthresh;
        end
         function ts=getSWSticky(obj)
            ssm=obj.SleepStateStruct.detectorinfo.detectionparms.SleepScoreMetrics.histsandthreshs;
            ts=ssm.stickySW;
        end

    end
    methods (Access=private)
        function range=getRange(obj,timeWindow)
            ss=obj.StatesSeries;
            twsec=seconds(timeWindow-ss.TimeInfo.StartDate);
            range=(ss.Time>twsec(1))&(ss.Time<=twsec(2));
        end
    end
end