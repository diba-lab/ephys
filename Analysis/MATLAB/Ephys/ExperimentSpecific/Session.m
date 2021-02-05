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
            params=SDExperiment.instance.get;
            %% SessionInfo
            sessionInfoFile=fullfile(baseFolder,params.FileLocations.Session.SessionInfo);
            folder=fileparts(sessionInfoFile);
            if ~isfolder(folder), mkdir(folder);end
            try 
                sessionInfo=readstruct(sessionInfoFile);
            catch
                sessionInfo.baseFolder=baseFolder;
                sessionInfo.Date='';
                sessionInfo.Notes='';
                sessionInfo.Condition='';                
                writestruct(sessionInfo,sessionInfoFile)
            end
            obj.SessionInfoFile=sessionInfoFile;
            obj.SessionInfo=sessionInfo;
            %% Blocks
            blockFile=fullfile(baseFolder,params.FileLocations.Session.Blocks);
            try 
                blockstt=readtimetable(blockFile,'Delimiter',',');
            catch
                blocks=params.Blocks.Block;
                blockstt=[];
                for iblock=1:numel(blocks)
                    t1=datetime('now','Format','HH:mm:ss');
                    t2=datetime('now','Format','HH:mm:ss')+hours(3);
                    Block=blocks(iblock);
                    blockstt=[blockstt; timetable(t1, t2, Block)];
                end             
                writetimetable(blockstt,blockFile);
            end
            sdblock= SDBlocks(obj.SessionInfo.Date,blockstt);
            obj.Blocks=sdblock;
            %% Probe
            try
                list=dir(fullfile(baseFolder,strcat('*Probe*.xlsx')))
                probe=Probe(fullfile(list.folder,list.name));
                obj.Probe=probe;
            catch
            end

        end
        
        function obj = setAnimal(obj,animal)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Animal = animal;
        end
        function obj = setProbe(obj,probe)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            sde=SDExperiment.instance.get;
            probeFile=fullfile(obj.SessionInfo.baseFolder,sde.FileLocations.Session.Probe);
            if nargin>1
                obj.Probe = probe;
                
            else
                % load templateProbe
                obj.Probe=Probe(sde.FileLocations.General.ProbeTemplate);
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
            idx=true(height(blocks),1);
            if nargin>1
                idx= ismember(blocks.Block,varargin);
            end
            blocks=blocks(idx,:);
        end
        function data = getDataLFP(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pr=Preprocess(obj);
            data=pr.getDataForLFP;
        end
        function data = getDataClustering(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pr=Preprocess(obj);
            data=pr.getDataForClustering;
        end
        
    end
end

