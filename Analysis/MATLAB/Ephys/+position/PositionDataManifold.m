classdef PositionDataManifold < position.PositionData
    %POSITIONDATAMANIFOLD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        parent
        manifold
        dataOriginal
        config
    end
    
    methods
        function obj = PositionDataManifold(positionData,manifold)
            %POSITIONDATAMANIFOLD Construct an instance of this class
            %   Detailed explanation goes here
            obj.parent=positionData;
            obj.units=positionData.units;
            obj.channels=positionData.units;
            obj.time=positionData.time;
            obj.dataOriginal=positionData.data;
            data1=table2array(positionData.data)';
            data2=manifold.map(data1);
            data3=[data2(:,1) zeros(size(data2,1),1) data2(:,2)];
            obj.data=array2table(data3,"VariableNames",{'X','Y','Z'});
            obj.manifold=manifold;
        end
        function data=getData(obj)
            data=obj.data;
        end        
        function data=getOriginalData(obj)
            data=obj.dataOriginal;
        end        
        function positionData1D=get1DData(obj)
            positionData=obj;
            positionData1D=position.PositionData1D(positionData);
        end        
        function [] = plotManifold(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.manifold.plotGraph
        end

        function [obj, folder]= saveInPlainFormat(obj,folder)
            ext2='position.points.mapped.csv';
            if exist('folder','var')
                [obj, folder]= saveInPlainFormat@position.PositionData(obj,folder);
            else
                [obj, folder]= saveInPlainFormat@position.PositionData(obj);
            end
            time=obj.time;
            timestr=matlab.lang.makeValidName(time.tostring);
            file2=fullfile(folder,[timestr ext2]);
            writetable(obj.datamapped,file2);
        end
        function obj = loadPlainFormat(obj,folder)
            ext1='position.points.csv';
            ext2='position.points.mapped.csv';
            [file2 uni]=obj.getFile(folder,ext2);
            if exist('folder','var')
                file1=fullfile(folder,[uni ext1]);
                obj= loadPlainFormat@position.PositionData(obj,file1);
            else
                obj= loadPlainFormat@position.PositionData(obj);
            end
            obj.datamapped=readtable(file2);
        end

    end
end

