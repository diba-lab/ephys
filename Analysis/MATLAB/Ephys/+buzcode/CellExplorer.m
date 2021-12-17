classdef CellExplorer < buzcode.BuzcodeStructure
    %CELLEXPLORER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Session
        Spikes
        CellMetrics
    end
    
    methods
        function obj = CellExplorer(basepath)
            %CELLEXPLORER Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@buzcode.BuzcodeStructure(basepath);
            pwd1=pwd;
            obj.Session=sessionTemplate(basepath,'showGUI',true);
            cd(pwd1);
            try
                obj=obj.loadSpikes;
            catch er
                cd(pwd1);
                er.getReport
            end
            try
                obj.CellMetrics=loadCellMetrics('basepath',basepath);
            catch er
                cd(pwd1);
                er.getReport
            end
        end

        function obj = loadSpikes(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isfield(obj.Session,'spikeSorting')
                sess=obj.Session.spikeSorting;
            else

            end
            session=obj.Session;

            for is=1:numel(sess)
                ses=sess{is};
                session.general.basePath=fullfile(obj.BasePath,ses.relativePath);
                session.spikeSorting{is}.relativePath='';
                session.extracellular=[];
                session.channelTags.Bad=[];
                
                obj.Session.extracellular.spikeGroups.channels{is}=(1:32)+(is-1)*32;
                obj.Session.extracellular.electrodeGroups.channels{is}=(1:32)+(is-1)*32;
                obj.Session.extracellular.spikeGroups.label{is}=['s' num2str(is)];
                obj.Session.extracellular.electrodeGroups.label{is}=['s' num2str(is)];
                try
                    spk=buzcode.SpikeArray(loadSpikes( ...
                        'session',session, ...
                        'forceReload',false,...
                        'showWaveforms',false, ...
                        'labelsToRead',{'good','mua'}));
                    spk.Spike.cluID=spk.Spike.cluID+10000*(is-1);
                    spk.Spike.maxWaveformCh=spk.Spike.maxWaveformCh+(is-1)*32;
                    spk.Spike.maxWaveformCh1=spk.Spike.maxWaveformCh1+(is-1)*32;
                    spk.Spike.shankID(:)=is;
                    ch=spk.Spike.channels_all;
                    for ispk=1:numel(ch)
                        spk.Spike.channels_all{ispk}=spk.Spike.channels_all{ispk}+(is-1)*32;
                        spk.Spike.maxWaveform_all{ispk}=spk.Spike.maxWaveform_all{ispk}+(is-1)*32;
                    end
                    if exist("spkR","var")
                        spkR=spkR+spk;
                    else
                        spkR=spk;
                    end
                catch er
                    display(er.getReport)
                end
            end
            spkR.Spike.basepath=obj.BasePath;
            obj.Session.extracellular.nChannels=max(spkR.Spike.channels_all{end});
            obj.Spikes=spkR.Spike;
        end
        function obj=openSession(obj)
            pwd1=pwd;
            obj.Session=sessionTemplate(obj.Session,'showGUI',true);
            cd(pwd1);
        end

        function obj=processCellMetrics(obj)
            pwd1=pwd;
            obj.CellMetrics=ProcessCellMetrics( ...
                'session',obj.Session, ...
                'spikes',obj.Spikes, ...
                'includeInhibitoryConnections', true,...
                'transferFilesFromClusterpath',false, ...
                'getWaveformsFromDat',false, ...
                'showGUI',true ...
                );
            cd(pwd1);
        end        
        function obj=processCellMetricsForBlock(obj,blockName)
            pwd1=pwd;
            ses=experiment.Session(obj.BasePath);
            blocks=ses.Blocks;
            ticd=obj.TimeIntervalCombined;
            bl=blocks.get(blockName)+blocks.Date;
            windowInSec=ticd.getSampleForClosest(bl)/ticd.getSampleRate;
            obj.CellMetrics=ProcessCellMetrics( ...
                'session',obj.Session, ...
                'spikes',obj.Spikes, ...
                'includeInhibitoryConnections', true,...
                'transferFilesFromClusterpath',false, ...
                'getWaveformsFromDat',false, ...
                'showGUI',false, ...
                'saveAs',['cell_metrics_' blockName], ...
                'restrictToIntervals',windowInSec, ...
                'manualAdjustMonoSyn', false...
                );
            cd(pwd1);
        end        
        function obj=openCellMetrics(obj)
            pwd1=pwd;
            CellExplorer('metrics',obj.CellMetrics)
            cd(pwd1);
        end
    end
end

