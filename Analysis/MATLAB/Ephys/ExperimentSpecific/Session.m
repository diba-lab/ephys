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
            obj.Blocks=blockstt;
            %% Probe
            ProbeFile=fullfile(baseFolder,params.FileLocations.Session.Probe);
            try 
                probeTable=readtable(ProbeFile);
            catch
                probeTemplateFile=params.FileLocations.General.ProbeTemplate;
                copyfile(probeTemplateFile, ProbeFile);
                probeTable=readtable(ProbeFile);
            end
            
            obj.Probe=Probe(probeTable);

        end
        
        function obj = setAnimal(obj,animal)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Animal = animal;
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
        
    end
end

