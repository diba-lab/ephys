classdef Session
    %SESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Animal
        SessionInfo
        Blocks
        Probe
    end
    properties (Access=private)
        SessionInfoFile
    end
    
    methods
        function obj = Session(baseFolder)
            %SESSION Construct an instance of this class
            %   Detailed explanation goes here
            logger=logging.Logger.getLogger;
            params=experiment.SDExperiment.instance.get;
            %% SessionInfo
            sessionInfoFile=fullfile(baseFolder,params.FileLocations.Session.SessionInfo);
            folder=fileparts(sessionInfoFile);
            if ~isfolder(folder), mkdir(folder);end
            try 
                sessionInfo=readstruct(sessionInfoFile);
                logger.info('Session info file is loaded.')
            catch
                sessionInfo.baseFolder=baseFolder;
                sessionInfo.Date='';
                sessionInfo.Notes='';
                sessionInfo.ZeitgeberTime='hh:mm:ss';
                sessionInfo.Condition='';                
                writestruct(sessionInfo,sessionInfoFile)
                logger.info(strcat('No session info file. It is created.\t', sessionInfoFile))
            end
            obj.SessionInfoFile=sessionInfoFile;
            obj.SessionInfo=sessionInfo;
            if ~strcmp(sessionInfo.baseFolder,baseFolder)
                sessionInfo.baseFolder=baseFolder;
                obj=obj.setSessionInfo(sessionInfo);
            end
            %% Blocks
            blockFile=fullfile(baseFolder,params.FileLocations.Session.Blocks);
            try 
                blockstt=readtimetable(blockFile,'Delimiter',',');
                logger.info('Experimental Block file is loaded.')
            catch
                blocks=params.Blocks.Block;
                blockstt=[];
                for iblock=1:numel(blocks)
                    t1=datetime('now','Format','HH:mm:ss');
                    t2=datetime('now','Format','HH:mm:ss')+hours(3);
                    Block=blocks(iblock);
                    blockstt=[blockstt; timetable(t1, t2, Block)]; %#ok<AGROW>
                end             
                writetimetable(blockstt,blockFile);
                logger.info(strcat('No experimental blocks file. It is created.\t', blockFile))
            end
            sdblock=experiment.SDBlocks(obj.SessionInfo.Date,blockstt);
            try sdblock.ZeitgeberTime=obj.SessionInfo.ZeitgeberTime; catch,end
            obj.Blocks=sdblock;
            try
                logger.info(sdblock.print)
                %% Location
%                 LocFile=fullfile(baseFolder,params.FileLocations.Session.Location);
                
            catch
                
            end
            %% Probe
            key=fullfile(baseFolder,strcat('*Probe*.xlsx'));
            list=dir(key);
            try
                probe=neuro.probe.Probe(fullfile(list().folder,list.name));
                obj.Probe=probe;
                logger.info('Probe file is loaded.')
%                 logger.info(probe.print)
            catch
                logger.info(strcat('No probe file. ', key))
            end
        end
        
        function obj = setAnimal(obj,animal)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Animal = animal;
        end
        function sesstr = toString(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            an=sprintf('%s\t -->',obj.Animal.Code);
            sesstr=sprintf('%s\t%s\nZT %s%s\n%s',an,obj.SessionInfo.Condition, ...
                obj.SessionInfo.ZeitgeberTime, ...
                obj.Blocks.print, ...
                obj.Probe.toString ...
                );
        end
        function obj = setProbe(obj,probe)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            sde=experiment.SDExperiment.instance.get;
            probeFile=fullfile(obj.SessionInfo.baseFolder,sde.FileLocations.Session.Probe);
            if nargin>1
                obj.Probe = probe;
                
            else
                % load templateProbe
                obj.Probe=neuro.probe.Probe(sde.FileLocations.General.ProbeTemplate); 
                warning('No Probe File. Template is loaded.');
            end
            obj.Probe.saveProbeTable(probeFile);
        end
        function obj = setSessionInfo(obj,sessionInfoStruct)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            writestruct(sessionInfoStruct,obj.SessionInfoFile)
            obj.SessionInfo = sessionInfoStruct;
        end
        function obj = setCondition(obj,condition)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            sessionInfoStruct=obj.SessionInfo;
            sessionInfoStruct.Condition=condition;
            obj=obj.setSessionInfo(sessionInfoStruct);
        end
        function blocks = getBlock(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            blocks=obj.Blocks;
            if nargin>1
                blocks= blocks.get(varargin{:});
            end
        end
        function data = getDataLFP(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pr=preprocessing.Preprocess(obj);
            data=pr.getDataForLFP;
        end
        function data = getDataClustering(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pr=preprocessing.Preprocess(obj);
            data=pr.getDataForClustering;
        end
        function zt = getZeitgeberTime(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            try
                ticd=neuro.time.TimeIntervalCombined(obj.SessionInfo.baseFolder);
                zt=ticd.getZeitgeberTime;
            catch
                zt=nan;
            end
        end
        function pos = getPosition(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            relativePath='_Position';
            relpath=fullfile(obj.SessionInfo.baseFolder,relativePath);
            try
                pos=position.PositionDataTimeLoaded(relpath);
            catch er
                er.message
                pos=[];
            end
        end
        function pos = getPositionMapped(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            relativePath='_Position';
            try
                relpath=fullfile(obj.SessionInfo.baseFolder,relativePath);
                pos=position.PositionDataTimeLoaded(relpath);
            catch er
                er.message
                pos=[];
            end
        end
        function sa = getUnits(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            us=buzcode.CellMetricsSession(char(obj.SessionInfo.baseFolder));
            sa=us.getSpikeArray;
        end
        
    end
end

