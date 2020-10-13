classdef BuzcodeStructure
    %BUZCODESTRUCTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        BasePath
        TimeIntervalCombined
        Probe
    end
    
    methods
        function obj = BuzcodeStructure(filepath)
            %Select from no input
            if ~exist('filepath','var')
                defpath='/data/EphysAnalysis/SleepDeprivationData/';
                defpath1={'*.eeg;*.lfp;*.dat;*.mat','Binary Record Files (*.eeg,*.lfp,*.dat)'};
                title='Select basepath';
                [~,filepath,~] = uigetfile(defpath1, title, defpath,'MultiSelect', 'off');
            end
            if isfolder(filepath)
                folder=filepath;
            else
                [folder,~,~]=fileparts(filepath);
            end
            exts={'.lfp','.eeg','.dat'};
            for iext=1:numel(exts)
                theext=exts{iext};
                thefile=dir(fullfile(folder,['*' theext]));
                if numel(thefile)>0
                    break
                end
            end
            obj.BasePath=filepath;
            
            try
                list=dir(fullfile(obj.BasePath,'*Probe*'));
                obj.Probe=Probe(fullfile(list.folder,list.name));
            catch
                fprintf('No Probe File at: %s',obj.BasePath);
            end
            try
                list=dir(fullfile(obj.BasePath,'*TimeInterval*'));
                S=load(fullfile(list.folder,list.name));
                fnames=fieldnames(S);
                obj.TimeIntervalCombined=S.(fnames{1});
            catch
                fprintf('No TimeIntervalCombined File at: %s',obj.BasePath);
            end
        end
        function ripple = calculateSWR(obj)
            folders={'.','..',['..',filesep,'..']};
            for ifolder=1:numel(folders)
                list=dir(fullfile(obj.BasePath,folders{ifolder},'*.conf'));
                if ~isempty(list)
                    break
                end
            end
            conf=readConf(fullfile(list.folder,list.name));
            chans=str2double( conf.channnels);
            try close Probe ;catch, end; figure('Name','Probe');
            obj.Probe.plotProbeLayout(chans);
            list1=dir(fullfile(obj.BasePath,'*.xml'));
            str=DataHash(conf);
            cacheFileName=fullfile(obj.BasePath,'cache',[str '.mat']);
            [folder,~,~]=fileparts(cacheFileName);
            if ~isfolder(folder), mkdir(folder); end
            ripple=detect_swr(fullfile(list1.folder,list1.name),chans,[]...
                ,'EVENTFILE',str2double( conf.eventfile)...
                ,'FIGS',str2double( conf.figs)...
                ,'swBP',str2double( conf.swbp)...
                ,'ripBP',str2double( conf.ripbp)...
                ,'WinSize',str2double( conf.winsize)...
                ,'Ns_chk',str2double( conf.ns_chk)...
                ,'thresSDswD',str2double( conf.thressdswd)...
                ,'thresSDrip',str2double( conf.thressdrip)...
                ,'minIsi',str2double( conf.minisi)...
                ,'minDurSW',str2double( conf.mindursw)...
                ,'maxDurSW',str2double( conf.maxdursw)...
                ,'minDurRP',str2double( conf.mindurrp)...
                ,'DEBUG',str2double( conf.debug)...
                );
            
            ripple1=Ripple(ripple)
        end
    end
end

