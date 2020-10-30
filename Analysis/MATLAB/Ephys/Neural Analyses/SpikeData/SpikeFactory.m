classdef SpikeFactory < SpikeNeuroscope
    %SPIKEFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    properties
        
    end
    
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function obj = SpikeFactory()
            % Initialise your custom properties.
        end
    end
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = SpikeFactory();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    methods
        function [sa, foldername]= getSpykingCircusOutputFolder(obj,foldername)
            defaultloc='/data/EphysAnalysis/cluster';
            title='Select folder for spike data';
            if ~exist('foldername','var')
                foldername = uigetdir(defaultloc,title);
            elseif ~isfolder(foldername)
                foldername = uigetdir(defaultloc,title);
            end
            try
                theFile=dir(fullfile(foldername,'..','..',['*TimeIntervalCombined*' '.mat']));
                S=load(fullfile(theFile.folder, theFile.name));
                fnames=fieldnames(S);
                ticd=S.(fnames{1});
                fprintf('TimeIntervalCobined is loaded.\n')
            catch
                warning('TimeIntervalCobined is not loaded.\n')
            end
            cluster_info=SpikeFactory.getTSVClusterInfoFileintoTable(fullfile(foldername,'cluster_info.tsv'));
            
            theFile=dir(fullfile(foldername,['spike_clusters' '.npy']));
            spikeclusters=readNPY(fullfile(theFile.folder, theFile.name));
            interestedFiles={'amplitudes';...
                'spike_times'};
            for ifile=1:numel(interestedFiles)
                aFile=interestedFiles{ifile};
                theFile=dir(fullfile(foldername,[aFile '.npy']));
                temps{ifile}=readNPY(fullfile(theFile.folder, theFile.name));
            end
            groups={'good','mua'};
            sas=[];
            for igroup=1:numel(groups)
                group=groups{igroup};
                ClusterIds=cluster_info.id(ismember(cluster_info.group,group));
                idx=ismember(spikeclusters, ClusterIds);
                for ifile=1:numel(interestedFiles)
                    aFile=interestedFiles{ifile};
                    temp=temps{ifile};
                    data.(aFile)=temp(idx);
                end
                data.spike_clusters=spikeclusters(idx);
                
                sa=SpikeArray(data.spike_clusters,data.spike_times);
                sa=sa.setTimeIntervalCombined(ticd);
                
                sa=sa.setClusterInfo(cluster_info(ismember(cluster_info.id,ClusterIds),:));
                ts=tokenize(theFile.folder,filesep);
                filename=fullfile(theFile.folder,'..',ts{numel(ts)-1});
                obj.saveCluFile([filename '.' group '.clu.0'],sa.SpikeTable.SpikeCluster);
                obj.saveResFile([filename '.' group '.res.0'],sa.SpikeTable.SpikeTimes);
            end
            
        end
    end
    
    methods (Static, Access=private)
        function clustergroup=getTSVGroupFileintoTable(filepath)
            %% Setup the Import Options and import the data
            opts = delimitedTextImportOptions("NumVariables", 2);
            
            % Specify range and delimiter
            opts.DataLines = [2, Inf];
            opts.Delimiter = "\t";
            
            % Specify column names and types
            opts.VariableNames = ["cluster_id", "group"];
            opts.VariableTypes = ["double", "categorical"];
            
            % Specify file level properties
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            
            % Specify variable properties
            opts = setvaropts(opts, "group", "EmptyFieldRule", "auto");
            
            % Import the data
            clustergroup = readtable(filepath, opts);
        end
        function clustergroup=getTSVClusterInfoFileintoTable(filepath)
            %% Setup the Import Options and import the data
            opts = delimitedTextImportOptions("NumVariables", 9);
            
            % Specify range and delimiter
            opts.DataLines = [2, Inf];
            opts.Delimiter = "\t";
            
            % Specify column names and types
            opts.VariableNames = {'id','amp','ch','depth','fr','group','n_spikes','purity','sh'};
            opts.VariableTypes = {'double','double','double','double','double', 'categorical','double','double','double'};
            
            % Specify file level properties
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            
            % Specify variable properties
            opts = setvaropts(opts, "group", "EmptyFieldRule", "auto");
            
            % Import the data
            clustergroup = readtable(filepath, opts);
        end
    end
end

