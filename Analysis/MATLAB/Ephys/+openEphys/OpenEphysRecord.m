classdef (Abstract)OpenEphysRecord < time.Timelined & file.BinarySave
    %OPENEPHYSRECORD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        Data
        TimeInterval
        Channels % Array hold only channel numbers like [1 2 3 ...]
        FileLoaderMethod
        Events
        Probe
    end
    properties (Access = private)
    end
    methods (Abstract)
        
    end
    
    methods
        function obj = OpenEphysRecord(filename)
            %OPENEPHYSRECORD Construct an instance of this class
            %   Detailed explanation goes here
            [filepath,~,ext]=fileparts(filename);
            switch ext
                case '.oebin'
                    fileLoaderMethod = file.FileLoaderBinary(filename);
                case '.openephys'
                    fileLoaderMethod = file.FileLoaderOpenEphys(filename);
                case '.lfp'
                    fileLoaderMethod = file.FileLoaderLFP(filename);
                otherwise
                    
            end
            obj.FileLoaderMethod=fileLoaderMethod;
            try 
                obj.Probe=neuro.probe.Probe([filepath filesep '..' filesep '..' ]);
            catch
                l=logging.Logger.getLogger;
                l.error('You should provide a probe file in %s',[filepath filesep '..' filesep '..' ]);
            end
            obj.Events=[];
        end
        %% Functions
        
        function channel=getChannel(obj,chan)
            D = obj.Data;
            dat = double(D.Data.mapped(chan,:));
            channel = neuro.basic.Channel(num2str(chan), dat, obj.getTimeInterval);
        end
        %%%% THIS PART WILL BE UPDATED!
        function combined=getTimeWindow(obj, timeWindow)
            ts=obj.getTimeInterval;
            if nargin<2
                timeWindow=[ts(1) ts(end)];
            end
            try
                timeWindowInSeconds=seconds(timeWindow - obj.getRecordStartTime);
            catch
                timeWindowInSeconds=timeWindow;
            end
            idx=(timeWindowInSeconds(1)<ts)&...
                (timeWindowInSeconds(2)>=ts);
            selectedTimePoints=ts(idx);
            tsc=tscollection(selectedTimePoints);
            tsc.TimeInfo.StartDate=obj.getRecordStartTime;
            D = obj.Data;
            dat = double(D.Data.mapped(:,idx));
            for ichan=1:numel(obj.getChannelNames)
                ts1=timeseries(dat(ichan,:),selectedTimePoints,'Name',...
                    obj.getChannelNames{ichan});
                ts1.TimeInfo.StartDate=obj.getRecordStartTime;
                tsc=tsc.addts(ts1);
            end
            combined=neuro.basic.ChannelTimeDataHard(tsc);
        end
        %%%%%%
        function newOpenEphysRecordsCombined = plus(obj,recordToAdd)
            newOpenEphysRecordsCombined=openEphys.OpenEphysRecordsCombined(obj,recordToAdd);
        end
        
        
        %% PLOTS
        function display(obj) %#ok<DISPLAY>
            %% TODO
            % List recording time and propetrites
            % additionalrecording properties can be listed here.
            file=obj.Data.Filename;
            ti=obj.getTimeInterval;
            fprintf('\n%s\n\t %s-%s (%s), %d channels @%d Hz\n', ...
                file, datestr(ti.getStartTime,0), datestr(ti.getEndTime,13), ...
                duration(ti.getEndTime-ti.getStartTime,"Format","hh:mm:ss.SSS"), ...
                numel(obj.getChannelNames),ti.getSampleRate)
            
        end
    end
    
    %% File Interactions
    methods (Access=public)
        
    end
    
    %% GETTER and SETTERS
    methods (Access=public)
        
        function events = getEvents(obj)
            events=obj.Events;
            s=events.Timestamps;
            if ~isempty(s)
                a=time.Absolute(time.Sample(s,obj.getTimeInterval.SampleRate),obj.getTimeInterval.StartTime);
                tt=timetable(a.time, events.ChannelIndex, logical(events.FullWords),'VariableNames',{'Channel','On-Off'});
                events=neuro.event.Events(tt,events.Header);
            else
                events=neuro.event.Events();
            end
        end
        function obj = addEvents(obj,evts)
            
        end
        function obj = setEvents(obj,evts)
            obj.Events=evts;
        end
        function ts = getTimeline(obj)
        end
        function data=getData(obj)
            data=obj.Data;
        end
        
        function file=getFile(obj)
            file=obj.Data.Filename;
        end
        
        function obj=setData(obj, Data)
            obj.Data=Data;
        end
        
        function time=getXMLSettings(obj)
            time=obj.Header.SettingsAtXMLFile;
        end
        
        function sampleRate=getSampleRate(obj)
            sampleRate=obj.Header.getSampleRate;
        end
        
        function obj=setSampleRate(obj,samplerate)
            hdr=obj.Header;
            obj.Header=hdr.setSampleRate(samplerate);
        end
        
        function st=getRecordStartTime(obj)
            ti=obj.TimeInterval;
            st=ti.getStartTime;
        end
        function st=getRecordEndTime(obj)
            ti=obj.TimeInterval;
            st=ti.getEndTime;
        end
        
        function ti=getTimeInterval(obj)
            ti=obj.TimeInterval;
        end
        
        function obj=setTimeInterval(obj,timeinterval)
            obj.TimeInterval=timeinterval;
        end
        
        function flm=getFileLoaderMethod(obj)
            flm=obj.FileLoaderMethod;
        end
        function h=getHeader(obj)
            h=obj.Header;
        end
        function obj=setChannels(obj,chans)
            obj.Channels=chans;
        end
        
        function chans=getChannelNames(obj)
            try
                pr=obj.Probe;
                chans=pr.getActiveChannels;
            catch
                chans=obj.Channels;
            end
        end
        function probe=getProbe(obj)
            probe=obj.Probe;
        end
        function ind=getChannelIndexes(obj,channels)
            tbl1=obj.getHeader.getChannelsTable;
            tbl=struct2table(tbl1);
            if iscellstr(channels)||isstring(channels)
                ind=ismember(tbl.channel_name,channels);
                ind=find(ind);
            elseif ischar(channels)
                try
                    ind=strfndw(tbl.channel_name,channels);
                catch
                    ind=ismember(tbl.channel_name,channels);
                    ind=find(ind);
                end
            else
                channums=(tbl.recorded_processor_index+1);
                ind=ismember(channums,channels);
                ind=find(ind);
            end
            
        end
        function obj=setProbe(obj,probe)
            obj.Probe=probe;
            fprintf('Probe added.\n\t%s\n',probe);
        end
    end
    methods (Access=public)
        function obj=getDownSampled(obj, newRate, newFolder)
            currentRate=obj.getSampleRate;
            numberOfChannels=numel(obj.getChannelNames);
            currentFileName=obj.getFile;
            [~,name,~]=fileparts(currentFileName);
            start_end=string([obj.getRecordStartTime obj.getRecordEndTime],...
                'HH-mm-ss');
            name=[name '_' start_end{1} '_' start_end{2}];
            ext='.lfp';
            newFileName=fullfile(newFolder,...
                sprintf('%s_down-sampled-%d',name,newRate),...
                sprintf('%s_down-sampled-%d%s',name,newRate,ext));
            [path,name,~]=fileparts(newFileName);
            mkdir(path);
            headerFile=fullfile(path,[name '.header-and-timestamps.mat']);
            if ~exist(newFileName,'file')
                % preprocess it
                system(sprintf('process_resample -f %d,%d -n %d %s %s',...
                    currentRate, newRate, numberOfChannels,...
                    currentFileName, newFileName));
            end
            
            if ~exist(headerFile,'file')
                sampleRateRatio = obj.getSampleRate/newRate;
                
                ts=obj.getTimestamps;
                ts_downsampled=double(downsample(ts.Time, sampleRateRatio));
                tsc_down=tscollection(ts_downsampled);
                tsc_down.TimeInfo.StartDate=ts.TimeInfo.StartDate;
                tsc_down.TimeInfo.Format=ts.TimeInfo.Format;
                obj=obj.setTimestamps(tsc_down);
                obj=obj.setSampleRate(newRate);
                header=obj.getHeader;
                timestamps=obj.getTimestamps;
                save(headerFile,'header','timestamps','-v7.3');
            end
            obj=openephys.OpenEphysRecordFactory.getOpenEphysRecord(newFileName);
        end
        function out=saveChannels(obj, channels)
            [filepath, name, ext] = fileparts(obj.getFile);
            out=fullfile(filepath,sprintf('%s_ch%d-%d%s',...
                name, min(channels), max(channels), ext));
            if ~exist(out,'file')
                obj.keepChannels(obj.getFile, out, numel(obj.getChannelNames), channels );
            else
                warning('File is already exist.\n\t%s\n',out);
            end
        end
    end
    
    
    methods (Access=private)
        function probe=loadProbeFile(obj,filepath)
            list=dir(fullfile(filepath,'..','..','*Probe*.xlsx'));
            if numel(list)>0
                probe=neuro.probe.Probe(fullfile(list(1).folder,list(1).name)); %#ok<CPROPLC>
                printf('Probe file: \n\t%s',fullfile(list(1).folder,list(1).name));
            else
                list=dir(fullfile(filepath,'*Probe*.xlsx'));
                if numel(list)>0
                    probe=neuro.probe.Probe(fullfile(list(1).folder,list(1).name)); %#ok<CPROPLC>
                    printf('Probe file: \n\t%s',fullfile(list(1).folder,list(1).name));
                    
                else
                    a=dir(fullfile(filepath,'..','..'));
                    b=dir(fullfile(filepath));
                    warning('Couldn''t find a probe file in the folder :\n\t%s\nor\t%s\n',...
                        a(1).folder,b(1).folder);
                    probe=[];
                end
            end
        end
    end
end