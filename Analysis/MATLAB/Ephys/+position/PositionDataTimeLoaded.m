classdef PositionDataTimeLoaded< position.PositionData
    %LOCATIONDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        source
    end
    
    methods
        function obj = PositionDataTimeLoaded(folder)
            %LOCATIONDATA Construct an instance of this class
            %   ticd should be in TimeIntervalCombined foormat
            if (isstring(folder)||ischar(folder))&&isfolder(folder)
                obj=obj.loadPlainFormat(folder);
            else
                error(sprintf('\nCannot load %s.\n',folder));
            end
        end
        function [file1, folder]= saveInPlainFormat(obj,folder)
            ext1='position.points.csv';
            extt='position.time.csv';
            if exist('folder','var')
                if ~isfolder(folder)
                    folder= pwd;
                end
            else
                folder= fileparts(obj.source);
            end
            time=obj.time;
            timestr=matlab.lang.makeValidName(time.tostring);
            time.saveTable(fullfile(folder,[timestr extt]));
            file1=fullfile(folder,[timestr ext1]);
            writetable(obj.data,file1);
        end
        function obj= loadPlainFormat(obj,folder)
            ext1='position.points.csv';
            extt='position.time.csv';
            [file1, uni]=obj.getFile(folder,ext1);
            obj.source=file1;
            obj.data=readtable(obj.source);
            folder=fileparts(file1);
            obj.channels=obj.data.Properties.VariableNames;
            obj.time=neuro.time.TimeIntervalCombined( ...
                fullfile(folder,[uni extt]));
            if obj.time.timeIntervalList.length==1
                obj.time=obj.time.timeIntervalList.get(1);
            end
        end
        function [file2, uni]=getFile(~,folder,extension)
            if ~exist('folder','var')
                folder= pwd;
            end
            if isfile(folder)
                [folder1,name,ext1]=fileparts(folder);
                uni1=split([name ext1],extension);
                uni=uni1{1};
                file1=dir(fullfile(folder1,[uni,extension]));
            else
                file1=dir(fullfile(folder,['*' extension]));
                if numel(file1)>1
                    [name,folder1] = uigetfile({['*' extension],extension}, ...
                        'Selectone of the position files',folder);
                    file1=dir(fullfile(folder1,name));
                end
            end
            file2=fullfile(file1.folder,file1.name);
            [~,name,ext1]=fileparts(file2);
            uni1=split([name ext1],extension);
            uni=uni1{1};
        end
    end
end

