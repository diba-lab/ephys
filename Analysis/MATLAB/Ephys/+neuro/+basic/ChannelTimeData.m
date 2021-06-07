classdef ChannelTimeData < file.BinarySave
    %COMBINEDCHANNELS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        Probe
        TimeIntervalCombined
        Data
        Filepath
    end
    
    methods
        function newObj = ChannelTimeData(filepath)
            if isa(filepath,'neuro.basic.ChannelTimeData')
                newObj=filepath;
            else
                exts={'.lfp','.eeg','.dat'};
                logger=logging.Logger.getLogger;
                if ~exist('filepath','var')
                    defpath='/data/EphysAnalysis/SleepDeprivationData/';
                    defpath1={'*.eeg;*.lfp;*.dat;*.mat','Binary Record Files (*.eeg,*.lfp,*.dat)'};
                    title='Select basepath';
                    [file,folder,~] = uigetfile(defpath1, title, defpath,'MultiSelect', 'off');
                    for iext=1:numel(exts)
                        theext=exts{iext};
                        thefile=dir(fullfile(folder,['*' theext]));
                        if numel(thefile)>0
                            break
                        end
                    end
                elseif isfolder(filepath)
                    folder=filepath;
                    for iext=1:numel(exts)
                        theext=exts{iext};
                        thefile=dir(fullfile(folder,['*' theext]));
                        if numel(thefile)>0
                            break
                        end
                    end
                elseif isfile(filepath)
                    thefile=dir(filepath);
                    folder=thefile.folder;
                end
                if numel(thefile)>1
                    logger.warning('\nMultiple files: selecting the first one.\n\t%s\n\t%s',thefile.name)
                    thefile=thefile(1);
                end
                
                probe=neuro.probe.Probe(folder);
                logger.info(probe.toString)
                chans=probe.getActiveChannels;
                numberOfChannels=numel(chans);
                newObj.Probe=probe;
                samples=thefile.bytes/2/numberOfChannels;
                newObj.Data=memmapfile(fullfile(thefile.folder,thefile.name),...
                    'Format',{'int16' [numberOfChannels samples] 'mapped'});
                
                try
                    newObj.TimeIntervalCombined=neuro.time.TimeIntervalCombined(folder);
                catch
                    numberOfPoints=samples;
                    prompt = {'Start DateTime:','SampleRate:'};
                    dlgtitle = 'Input';
                    dims = [1 35];
                    definput = {'11-Aug-2011 11:11:11','1250'};
                    answer = inputdlg(prompt,dlgtitle,dims,definput);
                    startTime=datetime(answer{1},'InputFormat','dd-MMM-yyyy HH:mm:ss');
                    sampleRate=str2num(answer{2});
                    ti=neuro.time.TimeInterval(startTime, sampleRate, numberOfPoints);
                    ticd=neuro.time.TimeIntervalCombined(ti);
                    ticd.save(folder);
                    newObj.TimeIntervalCombined=ticd;
                end
                logger.info(newObj.TimeIntervalCombined.tostring)
                newObj.Filepath=newObj.Data.Filename;
            end
        end
        function str=toString(obj)
            ticd=obj.TimeIntervalCombined;
            probe=obj.Probe;
            file1=dir(obj.Filepath);
            GB=file1.bytes/1024/1024/1024;
            str=sprintf('\n%s (%.2fGB)\n%s\n%s', obj.Filepath, GB, ticd.tostring, probe.toString);
        end
        function chnames=getChannelNames(obj)
            probe=obj.Probe;
            chnames=probe.getActiveChannels;
        end
        function ch = getChannel(obj,channelNumber)
            ticd=obj.getTimeIntervalCombined;
            probe=obj.Probe;
            channelList=probe.getActiveChannels;
            index=channelList==channelNumber;
            datamemmapfile=obj.Data;
            datamat=datamemmapfile.Data;
            voltageArray=datamat.mapped(index,:);
            ch=neuro.basic.Channel(channelNumber,voltageArray,ticd);
        end
        function LFP = getChannelsLFP(obj,channelNumber)
            ticd=obj.getTimeIntervalCombined;
            probe=obj.Probe;
            channelList=probe.getActiveChannels;
            if exist('channelNumber','var')
                index=ismember(channelList, channelNumber);
            else
                index=true(size(channelList));
            end
            datamemmapfile=obj.Data;
            datamat=datamemmapfile.Data;
            
            LFP.data=datamat.mapped(index,:);
            LFP.channels=channelList(index);
            LFP.sampleRate=ticd.getSampleRate;
        end
        function newobj = getDownSampled(obj, newRate, newFileName)
            if nargin>2
            else
                [newFolder,name,ext]=fileparts(obj.Filepath);
                newFileName=fullfile(newFolder, sprintf('%s_%dHz.lfp',name,newRate));
            end
            ticd=obj.TimeIntervalCombined;
            currentRate=ticd.getSampleRate;
            probe=obj.Probe;
            chans=probe.getActiveChannels;
            numberOfChannels=numel(chans);
            currentFileName=obj.Filepath;
            
            [folder1,name,~]=fileparts(newFileName);
            if ~exist(folder1,'dir'), mkdir(folder1);end
            probe.saveProbeTable(fullfile(folder1,strcat(name, '.Probe.xlsx')));
            ticd=ticd.getDownsampled(currentRate/newRate);
            ticd=ticd.saveTable(fullfile(folder1,strcat(name, '.TimeIntervalCombined.csv')));
            probe.createXMLFile(fullfile(folder1,strcat(name, '.xml')),newRate);
            if ~exist(newFileName,'file')
                % preprocess it
                system(sprintf('process_resample -f %d,%d -n %d %s %s',...
                    currentRate, newRate, numberOfChannels,...
                    currentFileName, newFileName));
            end
            newobj=neuro.basic.ChannelTimeData(newFileName);
        end
        %         function [] = plot(obj,varargin)
        %             try
        %                 channels=varargin{:};
        %             catch
        %                 tsc=obj.TimeseriesCollection;
        %                 channels=tsc.gettimeseriesnames;
        %             end
        %             hold on
        %             colors=othercolor('RdBu4',numel(channels))/1.5;
        %             colors=linspecer(numel(channels),'sequential')/1.5;
        %             for ichan=1:numel(channels)
        %                 subplot(numel(channels),1,ichan)
        %                 try
        %                     chname=channels{ichan};
        %                 catch
        %                     chname=['CH' num2str(channels(ichan))];
        %                 end
        %                 ch=obj.getChannels(chname);
        %                 %                 ch=ch.getHighpassFiltered(1000);
        %                 %                 ch=ch.getLowpassFiltered(50);
        %                 ch.plot('Color',colors(ichan,:));
        %                 ax=gca;
        %                 ax.YLim=[-1000 1000]*10;
        %                 ax.Position=[ax.Position(1)*2.5 ax.Position(2)...
        %                     ax.Position(3)*.8 ax.Position(4)*5];
        %                 axis off
        %             end
        %         end
        function out=getFolder(obj)
            out=fileparts(obj.Filepath);
        end
        function out=getFilepath(obj)
            out=obj.Filepath;
        end
        function out=getData(obj)
            out=obj.Data;
        end
        function out=getTimeIntervalCombined(obj)
            out=obj.TimeIntervalCombined;
        end
        function out=getProbe(obj)
            out=obj.Probe;
        end
        function obj=setTimeIntervalCombined(obj,ticd)
            obj.TimeIntervalCombined=ticd;
        end
        function obj=setProbe(obj,probe)
            obj.Probe=probe;
        end
        function obj=setFile(obj,file)
            obj.Filepath=file;
        end
        function save(obj)
            [folder,name,~]=fileparts(obj.Filepath);
            %% Probe, XML
            pr=obj.Probe;
            pr.saveProbeTable(fullfile(folder,strcat(name,'.Probe.xlsx')));
            pr.createXMLFile(fullfile(folder,strcat(name,'.xml')),obj.TimeIntervalCombined.getSampleRate)
            %% Ticd.
            ticd=obj.TimeIntervalCombined;
            ticd.saveTable(fullfile(folder,strcat(name,'.TimeIntervalCombined.csv')));
        end
    end
end