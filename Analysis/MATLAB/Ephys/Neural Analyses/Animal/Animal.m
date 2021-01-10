classdef Animal <AnimalMeta
    %ANIMAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ProbeMeta
    end
    
    methods
        function obj = Animal(struct)
            %ANIMAL Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@AnimalMeta(struct);
            obj.ProbeMeta=struct.ProbeName;
        end
        function probe=getProbe(obj)
            probename=obj.ProbeMeta;
            sde=SDExperiment.instance.get;
            probeFolder=sde.FileLocations.General.ProbeFolder;
            try
                list=dir(fullfile(probeFolder,strcat('*',probename,'*')));
                probe=Probe(fullfile(list.folder,list.name));
            catch
                probe=[];
            end
        end
    end
end

