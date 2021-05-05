classdef SpikeFactory < neuro.spike.SpikeNeuroscope
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
                obj = neuro.spike.SpikeFactory();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    methods
        function [sa, foldername]= getPhyOutputFolder(obj,foldername)
            logger=logging.Logger.getLogger;
            import neuro.time.*
            import neuro.spike.*
            defaultloc='/data/EphysAnalysis/cluster';
            title='Select folder for spike data';
            if ~exist('foldername','var')
                foldername = uigetdir(defaultloc,title);
            elseif ~isfolder(foldername)
                foldername = uigetdir(defaultloc,title);
            end

            theFile=dir(fullfile(foldername,'..',['*TimeIntervalCombined*' '.csv']));
            if isempty(theFile)
                theFile=dir(fullfile(foldername,'..','..',['*TimeIntervalCombined*' '.csv']));
                if isempty(theFile)
                    theFile=dir(fullfile(foldername,'..','..','..',['*TimeIntervalCombined*' '.csv']));
                else
                    logger.warning(strcat('TimeIntervalCobined is not loaded. \n\tLocation:\t',foldername,'\n'));
                end
            end
            ticd=TimeIntervalCombined(fullfile(theFile.folder, theFile.name));
            logger.info(['time is loaded.' ticd.tostring])
           
            try
                tsvfile=fullfile(foldername,'cluster_info.tsv');
                cluster_info=SpikeFactory.getTSVCluster(tsvfile);
                logger.info('cluster_info.tsv loaded');
            catch
                logger.error(strcat(fullfile(foldername,'cluster_info.tsv')))
            end
            theFile=dir(fullfile(foldername,['spike_clusters' '.npy']));
            spikeclusters=readNPY(fullfile(theFile.folder, theFile.name));
            interestedFiles={'amplitudes';...
                'spike_times'};
            for ifile=1:numel(interestedFiles)
                aFile=interestedFiles{ifile};
                theFile=dir(fullfile(foldername,[aFile '.npy']));
                temps{ifile}=readNPY(fullfile(theFile.folder, theFile.name));
                logger.info([aFile '.npy is loaded'])
            end
            paramfile='./ExperimentSpecific/PlottingRoutines/UnitPlots/UnitGroups.xml';
            params=readstruct(paramfile);
            if isfield(params,'exclude')
                idx=true(size(cluster_info.group));
                idx_ex=idx;
                exclude=params.exclude;
                logger.info(strjoin([strjoin(params.exclude,', '), 'is being excluded.'],' '))
                filename1='ex_';
                for iex=1:numel(exclude)
                    theex=exclude(iex);
                    idx_ex=idx_ex & ismember(cluster_info.group,theex);
                    filename1=strcat(filename1,theex,'_');
                end
                idx=idx & ~idx_ex;
            elseif isfield(params,'include')
                    idx=false(size(cluster_info.group));
                    idx_in=idx;
                    include=params.include;
                    logger.info(strjoin([strjoin(params.include,', '), 'is being include.'],' '))
                    filename1='in_';
                    for iin=1:numel(include)
                        thein=include(iin);
                        idx_in=idx_in | ismember(cluster_info.group,thein);
                        filename1=strcat(filename1,thein,'_');
                    end
                    idx=idx | idx_in;
            else
                logger.error(strcat(paramfile,' is incorrect. It should either include or exclude noise, good, mua, unsorted.'))
            end
            cluster_info_sel=cluster_info(idx,:);
            ClusterIds=cluster_info_sel.id;
            
            idx1=ismember(spikeclusters, ClusterIds);
            for ifile=1:numel(interestedFiles)
                aFile=interestedFiles{ifile};
                temp=temps{ifile};
                data.(aFile)=temp(idx1);
            end
            data.spike_clusters=spikeclusters(idx1);
            sa=SpikeArray(data.spike_clusters,data.spike_times);
            sa=sa.setTimeIntervalCombined(ticd);
            sa=sa.setClusterInfo(cluster_info_sel);
            sastr=sa.tostring('group','ch');
            logger.info(['Phy output folder loaded. ' sastr{:}])
            ts=split(theFile.folder,filesep);
            filename=fullfile(theFile.folder,ts{numel(ts)-1});
            obj.saveCluFile(strcat(filename, '.clu.0'),sa.SpikeTable.SpikeCluster);
            obj.saveResFile(strcat(filename, '.res.0'),sa.SpikeTable.SpikeTimes);
            logger.info(['.clu and .res files saved. ' theFile.folder])
        end
    end
    
    methods (Static, Access=private)
        function clustergroup=getTSVGroup(filepath)
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
        function clustergroup=getTSVCluster(filepath)
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

