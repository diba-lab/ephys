classdef ChannelTimeDataHard < file.BinarySave
    %ChannelTimeDataHard holding lfp data and provides functions to
    %manipulate it
    %   Detailed explanation goes here

    properties (Access=public)
        Probe
        TimeIntervalCombined
        Data
        Filepath
        Info
    end

    methods
        function newObj = ChannelTimeDataHard(filepath)
            if isa(filepath,'neuro.basic.ChannelTimeDataHard')
                newObj=filepath;
            else
                exts={'.lfp','.eeg','.dat'};
                logger=logging.Logger.getLogger;
                if ~exist('filepath','var')
                    defpath='/data/EphysAnalysis/SleepDeprivationData/';
                    defpath1={'*.eeg;*.lfp;*.dat;*.mat',['Binary Record ' ...
                        'Files (*.eeg,*.lfp,*.dat)']};
                    title='Select basepath';
                    [file,folder,~] = uigetfile(defpath1, title, defpath, ...
                        'MultiSelect', 'off');
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
                    logger.warning(['\nMultiple files: selecting the first' ...
                        ' one.\n\t%s\n\t%s'],thefile.name)
                    thefile=thefile(1);
                end

                probe=neuro.probe.Probe(folder);
                logger.info(['\n\t',probe.toString])
                chans=probe.getActiveChannels;
                numberOfChannels=numel(chans);
                newObj.Probe=probe;
                samples=thefile.bytes/2/numberOfChannels;
                newObj.Data=memmapfile(fullfile(thefile.folder,thefile.name),...
                    'Format',{'int16' [numberOfChannels samples] 'mapped'});

                try
                    newObj.TimeIntervalCombined=...
                        time.TimeIntervalCombined(folder);
                catch
                    numberOfPoints=samples;
                    prompt = {'Start DateTime:','SampleRate:'};
                    dlgtitle = 'Input';
                    dims = [1 35];
                    definput = {'11-Aug-2011 11:11:11','1250'};
                    answer = inputdlg(prompt,dlgtitle,dims,definput);
                    startTime=datetime(answer{1},'InputFormat',['dd-MMM-yyyy' ...
                        ' HH:mm:ss']);
                    sampleRate=str2num(answer{2});
                    ti=time.TimeInterval(startTime, sampleRate, ...
                        numberOfPoints);
                    ticd=time.TimeIntervalCombined(ti);
                    ticd.save(folder);
                    newObj.TimeIntervalCombined=ticd;
                end
                if newObj.TimeIntervalCombined.getNumberOfPoints>samples
                    ticd=time.TimeIntervalCombined;
                    ticd.Source=newObj.TimeIntervalCombined.Source;
                    if ticd.getNumberOfPoints==samples
                        newObj.TimeIntervalCombined=ticd;
                        ticd.saveTable
                    else
                        error(sprintf(['datsize(%d) size and .TimeIntervalCombined (%d) ' ...
                            'files don''t match.'],samples, ...
                            newObj.TimeIntervalCombined.getNumberOfPoints))
                    end
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
            str=sprintf('\n%s (%.2fGB)\n%s\n%s', obj.Filepath, GB, ...
                ticd.tostring, probe.toString);
        end
        function chnames=getChannelNames(obj)
            probe=obj.Probe;
            chnames=probe.getActiveChannels;
        end
        function ctdh=getChanneltimeDataHardBad(obj)
            ctdh=neuro.basic.ChannelTimeDataHardBad(obj,Bad);
        end
        function ch = getChannel(obj,channelNumber)
            l=logging.Logger.getLogger;
            ticd=obj.getTimeIntervalCombined;
            probe=obj.Probe;
            channelList=probe.getActiveChannels;
            index=channelList==channelNumber;
            l.info(sprintf('Loading Channel %d from %s',channelNumber, ...
                obj.Filepath))
            datamemmapfile=obj.Data;
            datamat=datamemmapfile.Data;
            voltageArray=double(datamat.mapped(index,:));
            ch=neuro.basic.Channel(channelNumber,voltageArray,ticd);
        end
        function obj = addChannel(obj,channels)
            LFPticd=obj.getTimeIntervalCombined;
            datamat=obj.Data.Data.mapped;
            array=zeros(1,size(datamat,2));
            for ichan=1:numel(channels)
                channel=channels{ichan};
                ch=channel.getReSampled(LFPticd.getSampleRate);

                LFPtil=LFPticd.getTimeIntervalList.createIterator;
                while LFPtil.hasNext
                    LFPti=LFPtil.next;
                    chsub=ch.getTimeWindow([LFPti.getStartTime ...
                        LFPti.getEndTime]);
                    idx=LFPticd.getSampleForClosest( ...
                        chsub.getStartTime):LFPticd.getSampleForClosest( ...
                        chsub.getEndTime);
                    array(1,idx)=chsub.Values;
                end
                [obj.Probe, channum]=obj.Probe.addANewChannel(channel.ChannelName);
                array(isnan(array))=0;
                array1=int16((normalize(array,'range')-.5) *5000);
                if channum>size(datamat,1)
                    datamat=[datamat; array1];
                else
                    datamat(channum,:)=array1;
                end
            end
            probe=obj.Probe;
            [f,n,e]=fileparts(probe.getSource);folder=[f filesep '_LFP'];
            if ~isfolder(folder), mkdir(folder);end
            probe.saveProbeTable(fullfile(folder,[n e]));
            [~,n,e]=fileparts(obj.Filepath);
            probe.createXMLFile(fullfile(folder,[n '.xml']),LFPti.getSampleRate);

            fileID = fopen(fullfile(folder,[n e]),'w');
            fwrite(fileID, datamat,'int16');
            fclose(fileID);
            source=time.TimeIntervalCombined(f).Source;[~,n,e]=fileparts(source);

            copyfile(source,fullfile(folder,[n e]))
            obj=neuro.basic.ChannelTimeDataHard(folder);
        end
        function filewrite = addPositionFile(obj, channels)
            freq=1;
            width=400;linesw=linspace(0, width,20);
            height=50;linesh=linspace(0, height,numel(channels)+2);
            LFPticd=obj.getTimeIntervalCombined;
            fratio=LFPticd.getSampleRate/freq;
            LFPticdd=LFPticd.getDownsampled(fratio);
            array=zeros(numel(channels)*2,LFPticdd.getNumberOfPoints);
            for ichan=1:numel(channels)
                chan=channels{ichan};
                ch=chan.getReSampled(freq);
                LFPtil=LFPticdd.getTimeIntervalList.createIterator;
                while LFPtil.hasNext
                    LFPti=LFPtil.next;
                    chsub=ch.getTimeWindow([LFPti.getStartTime LFPti.getEndTime]);
                    idx=LFPticdd.getSampleForClosest(chsub.getStartTime):...
                        LFPticdd.getSampleForClosest(chsub.getEndTime);
                    try
                        array(ichan*2-1,idx)=chsub.Values;
                    catch e
                        if strcmp(e.identifier, 'MATLAB:subsassigndimmismatch')...
                                &&(numel(chsub.Values)-numel(idx))==1
                            array(ichan*2-1,idx)=chsub.Values(1:numel(idx));
                        else
                            error(e);
                        end
                    end
                end
                array(ichan*2,:)=round(linesh(ichan+1));
                array(ichan*2-1,:)=round(normalize(array(ichan*2-1,:),'range')...
                    *linesw(end-2)+linesw(2));
            end
            [f,n,e]=fileparts(obj.Filepath);folder=[f filesep '_Position'];
            if ~isfolder(folder), mkdir(folder);end
            array(isnan(array))=0;
            t=array2table(array');
            filewrite=fullfile(folder,[n '.' chan.getChannelName]);
            writetable(t,filewrite,FileType="text",WriteVariableNames=false,Delimiter='tab')
        end
        function obj = removeChannel(obj,channel)
            [obj.Probe, removed]=obj.Probe.removeChannel(channel);
            if removed
                probe=obj.Probe;
                probe.saveProbeTable;
                [folder,name,~]=fileparts(obj.Filepath);
                probe.createXMLFile(fullfile(folder,[name '.xml']),...
                    obj.getTimeIntervalCombined.getSampleRate);
                datamat=obj.Data.Data.mapped;
                if removed<=size(datamat,1)
                    datamat(removed,:)=[];
                end
                copyfile(obj.Filepath,strcat(obj.Filepath, '+', string(channel)))
                fileID = fopen([obj.Filepath],'w');
                fwrite(fileID, datamat,'int16');
                fclose(fileID);
            end
            obj=neuro.basic.ChannelTimeDataHard(obj.Filepath);
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
        function ctd = get(obj,channels,time)
            ticd1=obj.getTimeIntervalCombined;
            ticd=ticd1.getTimeIntervalForTimes(time);
            samples=ticd1.getSampleForClosest(time);
            probe=obj.Probe;
            channelList=probe.getActiveChannels;
            if exist('channels','var')
                ch_index=ismember(channelList, channels);
            else
                ch_index=true(size(channelList));
            end
            datamemmapfile=obj.Data;
            datamat=datamemmapfile.Data;

            data=datamat.mapped(ch_index,samples(1):samples(2));
            probe=probe.setActiveChannels(channels);
            time=ticd;
            ctd=neuro.basic.ChannelTimeData(probe.getActiveChannels,time,data);
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
                system(sprintf('process_resample -f %d,%d -n %d "%s" "%s"',...
                    currentRate, newRate, numberOfChannels,...
                    currentFileName, newFileName));
            end
            newobj=neuro.basic.ChannelTimeDataHard(newFileName);
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
            pr.createXMLFile(fullfile(folder,strcat(name,'.xml')),...
                obj.TimeIntervalCombined.getSampleRate)
            %% Ticd.
            ticd=obj.TimeIntervalCombined;
            ticd.saveTable(fullfile(folder,strcat(name,'.TimeIntervalCombined.csv')));
        end
    end
end