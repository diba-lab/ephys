classdef Preprocess
    %PREPROCESS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        OpenephysFiles
        Session
        ClusterParams
        LFPParams
        Bad
    end
    
    methods
        function obj = Preprocess(session)
            %PREPROCESS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Session = session;
            %% RawFiles
            sde=SDExperiment.instance.get;
            preprocessFile=fullfile(session.SessionInfo.baseFolder, sde.FileLocations.Preprocess.RawFiles);
            folder=fileparts(preprocessFile);
            if ~isfolder(folder), mkdir(folder);end
            try 
                files=readstruct(preprocessFile);
            catch
                files.RawsFiles.RawFile(1)="[/folder/*.oebin | /folder/*.openephys]";
                files.RawsFiles.RawFile(2)="[/folder/*.oebin | /folder/*.openephys]";
                writestruct(files,preprocessFile);
                open preprocessFile
            end
            obj.OpenephysFiles=files.RawsFiles.RawFile';
            %% Set Sesion Info
            if session.SessionInfo
            sesInfo=session.SessionInfo;
            
            fInfo=dir(obj.OpenephysFiles(1));
            sesInfo.Date=datetime(fInfo.date,'InputFormat','dd-MMM-uuuu HH:mm:ss','Format','uuuu-MM-dd');
            session=session.setSessionInfo(sesInfo);
            end
            
            %% Read Params For Clustering
            paramsCluFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.ForClustering);
            try
                forClu=readstruct(paramsCluFile);
            catch
                forClu.Shanks.Shank=[1 2 3 4];
                animal=session.Animal.Code;
                date=session.SessionInfo.Date;
                cond=session.SessionInfo.Condition;
                output=sde.FileLocations.Preprocess.OutputFolderForClustering;
                forClu.OutputFolder=fullfile(output,strcat(animal,'_',datestr(date,29),'_',cond));
                writestruct(forClu,paramsCluFile);
            end
            obj.ClusterParams=forClu;
            %% Read Params For LFP
            paramsLFPFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.ForLFP);
            try
                forLFP=readstruct(paramsLFPFile);
            catch
                forLFP.Shanks.Shank=[1 2 3 4];
                forLFP.DownSampleRate=1250;
                
                writestruct(forLFP,paramsLFPFile);
            end
            obj.LFPParams=forLFP;
            %% Bad channel and time
            badFile=fullfile(session.SessionInfo.baseFolder,sde.FileLocations.Preprocess.Bad);
            try
                bad=readstruct(badFile);
            catch
                bad.BadChannels.Channel(1)=nan;
                bad.BadTimes.Time(1).start=datetime('now','Format','HH:mm:ss.SSS');
                bad.BadTimes.Time(1).stop=datetime('now','Format','HH:mm:ss.SSS')+seconds(5);
                bad.BadTimes.Time(2).start=datetime('now','Format','HH:mm:ss.SSS');
                bad.BadTimes.Time(2).stop=datetime('now','Format','HH:mm:ss.SSS')+seconds(5);
                writestruct(bad,badFile);
            end
            obj.Bad=bad;
        end
        
        function dataForClustering = getDataForClustering(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outfol=obj.ClusterParams.OutputFolder
            if ~isfolder(outfol), mkdir(outfol);end
%             outputArg = obj.Property1 + inputArg;
        end
    end
end

