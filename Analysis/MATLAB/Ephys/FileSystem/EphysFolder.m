classdef EphysFolder
    %EPHYSFOLDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Folder
        Data
        Channel
        Time
        DataXML
    end
    
    methods
        function obj = EphysFolder(dataFile)
            %EPHYSFOLDER Construct an instance of this class
            %   Detailed explanation goes here
            dataFileTypes={'.dat','.lfp'};
            probeNames={'Probe'};
            times={'TimeIntervalCombined'};
            if isfile(dataFile)
                list=dir(dataFile);
                [dataFolder,name,ext] = fileparts(list.name);
            elseif isfolder(dataFile)
                dataFolder=dataFile;
            end
            %% load
            for fileTypes=dataFileTypes
                search=strcat('*',cell2mat(fileTypes));
                filelist=dir(fullfile(dataFolder, search));
                if numel(filelist)==1
                    obj.Data=fullfile(filelist.folder,filelist.name);
                    obj.Folder=filelist.folder;
                    break
                elseif numel(filelist)>1
                    error(sprintf('Multiple %s files in %s.',search,dataFolder));
                end
            end
            if ~isempty(obj.Data)
                [~,name,~]=fileparts(obj.Data);
                search=strcat(name,'.xml');
                filelist=dir(fullfile(dataFolder, search));
                if numel(filelist)==1
                    obj.DataXML=fullfile(filelist.folder,filelist.name);
                end
            end
            for fileTypes=probeNames
                search=strcat('*',cell2mat(fileTypes),'*');
                filelist=dir(fullfile(dataFolder, search));
                if numel(filelist)==1
                    obj.Channel=fullfile(filelist.folder,filelist.name);
                    break
                elseif numel(filelist)>1
                    error(sprintf('Multiple %s files in %s.',search,dataFolder));
                end
            end
            for fileTypes=times
                search=strcat('*',cell2mat(fileTypes),'*');
                filelist=dir(fullfile(dataFolder, search));
                if numel(filelist)==1
                    obj.Time=fullfile(filelist.folder,filelist.name);
                    break
                elseif numel(filelist)>1
                    error(sprintf('Multiple %s files in %s.',search,dataFolder));
                end
            end
            
        end
        
        function outputArg = getDataFile(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Data;
        end
        function outputArg = getFolder(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Folder;
        end
        function outputArg = getChannel(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
        function outputArg = getTime(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

