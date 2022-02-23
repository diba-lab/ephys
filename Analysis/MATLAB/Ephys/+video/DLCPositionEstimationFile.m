classdef DLCPositionEstimationFile
    %DLCPOSITIONESTIMATIONFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        File
        TrainExtension
        Markers
        Dims
        Time
        Data
    end
    
    methods
        function obj = DLCPositionEstimationFile(filename)
            %DLCPOSITIONESTIMATIONFILE Construct an instance of this class
            %   Detailed explanation goes here
            if isfile(filename)

                t=readtable(filename,'NumHeaderLines',2,'ReadVariableNames',true);
                tx=readcell(filename,'Range',[1 2 3 width(t)]);
                obj.Markers=unique(tx(2,:));
                obj.Dims=unique(tx(3,:),'stable');
                obj.TrainExtension=unique(tx(1,:),'stable');
                marker1=t.Properties.VariableNames;
                obj.Time=t.(marker1{1})';
                for imarker=1:numel(obj.Markers)
                    for idim=1:numel(obj.Dims)
                        dat(imarker,idim,:)=t.(marker1{(imarker-1)*3+idim+1});
                    end
                end
                obj.File=filename;
            else
                error('No file.')
            end
            obj.Data=dat;
        end    
    end
end

