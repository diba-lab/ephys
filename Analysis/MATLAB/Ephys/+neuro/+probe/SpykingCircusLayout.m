classdef (Abstract) SpykingCircusLayout
    %NEUROSCOPELAYOUT Summary of this class goes here
    %   Detailed explanation goes here

    properties

    end
    methods (Abstract)
        getSiteSpatialLayout(obj)
    end

    methods
        function [] = saveSpykingCircusPrbFile(obj,folder)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            fname1=split(folder,filesep);fname=fname1{end};
            file=fullfile(folder,[fname '.prb']);
            fid=fopen(file,"w");
            T=obj.getSiteSpatialLayout;
            T=T(T.isActive==1,:);
            fprintf(fid,'total_nb_channels = %d\n',height(T));
            fprintf(fid,'radius            = %d\n',150);
            %             fprintf(fid,'channel_groups    = {}\n');
            fprintf(fid,'\n');
            fprintf(fid,'channel_groups = {\n');
            shanks=unique(T.ShankNumber);
            grno=0;
            for igr=1:numel(shanks)
                fprintf(fid,'\t%d:\t{\n',grno);grno=grno+1;
                fprintf(fid,'\t\t''channels'': [');
                sh=shanks(igr);
                subT=T(T.ShankNumber==sh,:);
                for ichan=1:height(subT)
                    thechan=subT(ichan,:);
                    if thechan.ChannelNumberComingOutPreAmp<=height(T)
                        if ichan<height(subT)
                            fprintf(fid,'%d, ', thechan.ChannelNumberComingOutPreAmp-1);
                        else
                            fprintf(fid,'%d],\n', thechan.ChannelNumberComingOutPreAmp-1);
                        end
                    end
                end
                fprintf(fid,'\n');
                fprintf(fid,'\t\t''geometry'': {\n');
                for ichan=1:height(subT)
                    thechan=subT(ichan,:);
                    if thechan.ChannelNumberComingOutPreAmp<=height(T)
                        if ichan<height(subT)
                            fprintf(fid,'\t\t\t%d: [%.1f, %.1f],\n',...
                                thechan.ChannelNumberComingOutPreAmp-1, thechan.X, thechan.Z );
                        else
                            fprintf(fid,'\t\t\t%d: [%.1f, %.1f]\n',...
                                thechan.ChannelNumberComingOutPreAmp-1, thechan.X, thechan.Z );
                        end
                    end
                end
                fprintf(fid,'\t\t\t},\n');
                fprintf(fid,'\t\t''graph'': []\n\t\t}');
                if igr<numel(shanks)
                    fprintf(fid,',\n');
                else
                    fprintf(fid,'\n');
                end
            end
            fprintf(fid,'\t}\n');
        end
        function [] = saveSpykingCircusParamFile(obj,folder)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            pr.data.file_format='raw_binary';
            pr.data.stream_mode='None';
            f=dir(fullfile(folder,"*.prb"));
            pr.data.mapping=fullfile(f.folder,f.name);
            pr.data.suffix='crs';
            pr.data.overwrite='True';
            pr.data.parallel_hdf5='True';
            pr.data.output_dir='';
            pr.data.sampling_rate='30000';
            pr.data.data_dtype='int16';
            pr.data.nb_channels=num2str(numel(obj.getActiveChannels));
            pr.data.gain='0.19499999284744263';

            pr.detection.radius         = 'auto';       % Radius [in um] (if auto, read from the prb file)
            pr.detection.N_t            = '2';          % Width of the templates [in ms]
            pr.detection.spike_thresh   = '5';          % Threshold for spike detection
            pr.detection.peaks          = 'negative';   % Can be negative (default), positive or both
            pr.detection.dead_channels  = '';           % If not empty or specified in the probe, a dictionary {channel_group : [list_of_valid_ids]}

            pr.filtering.cut_off        = '500, auto';  % Min and Max (auto=nyquist) cut off frequencies for the band pass butterworth filter [Hz]
            pr.filtering.filter         = 'True';       % If True, then a low-pass filtering is performed
            pr.filtering.remove_median  = 'True';       % If True, median over all channels is substracted to each channels (movement artifacts)
            pr.filtering.common_ground  = '';           % If you want to use a particular channel as a reference ground: should be a channel number

            pr.triggers.trig_file      = '';           % External stimuli to be considered as putative artefacts [in trig units] (see documentation)
            pr.triggers.trig_windows   =  '';          % The time windows of those external stimuli [in trig units]
            pr.triggers.trig_unit      = 'ms';         % The unit in which times are expressed: can be ms or timestep
            pr.triggers.clean_artefact = 'False';      % If True, external artefacts induced by triggers will be suppressed from data
            pr.triggers.dead_file      = '';           % Portion of the signals that should be excluded from the analysis [in dead units]
            pr.triggers.dead_unit      = 'ms';         % The unit in which times for dead regions are expressed: can be ms or timestep
            pr.triggers.ignore_times   = 'False';      % If True, any spike in the dead regions will be ignored by the analysis
            pr.triggers.make_plots     = '';           % Generate sanity plots of the averaged artefacts [Nothing or None if no plots]

            pr.whitening.spatial        = 'True';       % Perform spatial whitening
            pr.whitening.max_elts       = '10000';      % Max number of events per electrode (should be compatible with nb_elts)
            pr.whitening.nb_elts        = '0.8';        % Fraction of max_elts that should be obtained per electrode [0-1]
            pr.whitening.output_dim     = '5';          % Can be in percent of variance explain, or num of dimensions for PCA on waveforms

            pr.clustering.extraction     = 'median-raw'; % Can be either median-raw (default) or mean-raw
            pr.clustering.sub_dim        = '5';          % Number of dimensions to keep for local PCA per electrode
            pr.clustering.max_elts       = '10000';      % Max number of events per electrode (should be compatible with nb_elts)
            pr.clustering.nb_elts        = '0.8';        % Fraction of max_elts that should be obtained per electrode [0-1]
            pr.clustering.nb_repeats     = '3';          % Number of passes used for the clustering
            pr.clustering.smart_search   = 'True';       % Activate the smart search mode
            pr.clustering.merging_method = 'nd-bhatta';  % Method to perform local merges (distance, dip, folding, nd-folding, bhatta, nd-bhatta)
            pr.clustering.merging_param  = 'default';    % Merging parameter (see docs) (3 if distance, 0.5 if dip, 1e-9 if folding, 2 if bhatta)
            pr.clustering.sensitivity    = '3';          % Single parameter for clustering sensitivity. The lower the more sensitive
            pr.clustering.cc_merge       = '0.95';       % If CC between two templates is higher, they are merged
            pr.clustering.dispersion     = '(5, 5)';     % Min and Max dispersion allowed for amplitudes [in MAD]
            pr.clustering.fine_amplitude = 'True';       % Optimize the amplitudes and compute a purity index for each template
            pr.clustering.make_plots     = '';         % Generate sanity plots of the clustering [Nothing or None if no plots]

            pr.fitting.amp_limits     = '(0.3, 30)' ; % Amplitudes for the templates during spike detection [if not auto]
            pr.fitting.amp_auto       = 'True'  ;     % True if amplitudes are adjusted automatically for every templates
            pr.fitting.collect_all    = 'False' ;     % If True, one garbage template per electrode is created, to store unfitted spikes
            pr.fitting.ratio_thresh   = '0.9';        % Ratio of the spike_threshold used while fitting [0-1]. The lower the slower

            pr.merging.erase_all      = 'True';     % If False, a prompt will ask you to remerge if merged has already been done
            pr.merging.cc_overlap     = '0.85';     % Only templates with CC higher than cc_overlap may be merged
            pr.merging.cc_bin         = '2';        % Bin size for computing CC [in ms]
            pr.merging.default_lag    = '5';        % Default length of the period to compute dip in the CC [ms]
            pr.merging.auto_mode      = '0.9';      % Between 0 (aggressive) and 1 (no merging). If empty, GUI is launched
            pr.merging.remove_noise   = 'True';     % If True, meta merging will remove obvious noise templates (weak amplitudes)
            pr.merging.noise_limit    = '0.75';     % Amplitude at which templates are classified as noise
            pr.merging.sparsity_limit = '0.75';     % Sparsity level (in percentage) for selecting templates as putative noise (in [0, 1])
            pr.merging.time_rpv       = '5';        % Time [in ms] to consider for Refraction Period Violations (RPV) (0 to disable)
            pr.merging.rpv_threshold  = '0.02';     % Percentage of RPV allowed while merging
            pr.merging.merge_drifts   = 'True';     % Try to automatically merge drifts, i.e. non overlapping spiking neurons
            pr.merging.drift_limit    = '1'  ;      % Distance for drifts. The higher, the more non-overlapping the activities should be

            pr.converting.erase_all      = 'True';       % If False, a prompt will ask you to export if export has already been done
            pr.converting.export_pcs     = 'all';     % Can be prompt [default] or in none, all, some
            pr.converting.export_all     = 'False';      % If True, unfitted spikes will be exported as the last Ne templates
            pr.converting.sparse_export  = 'False';       % For recent versions of phy, and large number of templates/channels
            pr.converting.prelabelling   = 'False';      % If True, putative labels (good, noise, best, mua) are pre-assigned to neurons
            pr.converting.rpv_threshold  = '0.05';       % Percentage of RPV allowed while labelling neurons as good neurons

            pr.validating.nearest_elec   = 'auto';       % Validation channel (e.g. electrode closest to the ground truth cell)
            pr.validating.max_iter       = '200';        % Maximum number of iterations of the stochastic gradient descent (SGD)
            pr.validating.learning_rate  = '1.0e-3';     % Initial learning rate which controls the step-size of the SGD
            pr.validating.roc_sampling   = '10';         % Number of points to estimate the ROC curve of the BEER estimate
            pr.validating.test_size      = '0.3';        % Portion of the dataset to include in the test split
            pr.validating.radius_factor  = '0.5';        % Radius factor to modulate physical radius during validation
            pr.validating.pr.validating.juxta_dtype    = 'uint16';     % Type of the juxtacellular data
            pr.validating.juxta_thresh   = '6';          % Threshold for juxtacellular detection
            pr.validating.juxta_valley   = 'False';      % True if juxta-cellular spikes are negative peaks
            pr.validating.juxta_spikes   = '';           % If none, spikes are automatically detected based on juxta_thresh
            pr.validating.filter         = 'True';       % If the juxta channel need to be filtered or not
            pr.validating.make_plots     = 'png';        % Generate sanity plots of the validation [Nothing or None if no plots]

            pr.extracting.safety_time    = '1';          % Temporal zone around which spikes are isolated [in ms]
            pr.extracting.max_elts       = '10000';       % Max number of collected events per templates
            pr.extracting.output_dim     = '5';          % Percentage of variance explained while performing PCA
            pr.extracting.cc_merge       = '0.975';      % If CC between two templates is higher, they are merged
            pr.extracting.noise_thr      = '0.8';        % Minimal amplitudes are such than amp*min(templates) < noise_thr*threshold

            pr.noedits.filter_done    = 'False';              %!! AUTOMATICALLY EDITED: DO NOT MODIFY !!
            pr.noedits.artefacts_done = 'False';      % Will become True automatically after removing artefacts
            pr.noedits.median_done    = 'Flase';              %!! AUTOMATICALLY EDITED: DO NOT MODIFY !!
            pr.noedits.ground_done    = 'False';      % Will become True automatically after removing common ground
            
            grs=fieldnames(pr);
            fname1=split(folder,filesep);fname=fname1{end};
            file=fullfile(folder,[fname '.params']);
            fid=fopen(file,"w");
            for igr=1:numel(grs)
                grname=grs{igr};
                prms=fieldnames(pr.(grname));
                fprintf(fid,'\n[%s]\n',grname);
                for ipr=1:numel(prms)
                    prname=prms{ipr};
                    prm=pr.(grname).(prname);
                    try
                        fprintf(fid,'%s \t= %s\n',prname,prm);
                    catch
                    end
                end
            end
        end
    end
end

