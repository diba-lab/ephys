classdef ChannelTimeData
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
            [folder,~,~]=fileparts(filepath);
            exts={'.lfp','.eeg','.dat'};
            for iext=1:numel(exts)
                theext=exts{iext};
                thefile=dir(fullfile(folder,['*' theext]));
                if numel(thefile)>0
                    break
                end
            end
            probefile=dir(fullfile(folder,'*Probe*'));
            probe=Probe(fullfile(probefile.folder,probefile.name));
            chans=probe.getActiveChannels;
            numberOfChannels=numel(chans);
            newObj.Probe=probe;
            samples=thefile.bytes/2/numberOfChannels;
            newObj.Data=memmapfile(fullfile(thefile.folder,thefile.name),...
                'Format',{'int16' [numberOfChannels samples] 'mapped'});
            timeFile=dir(fullfile(folder,'*TimeInterval*'));
            s=load(fullfile(timeFile.folder,timeFile.name));
            fnames=fieldnames(s);
            newObj.TimeIntervalCombined=s.(fnames{1});
            newObj.Filepath=newObj.Data.Filename;
        end
        
        function newobj = getChannel(obj,channelNames)
            ticd=obj.getTimeIntervalCombined;
            probe=obj.Probe;
            channelList=probe.getActiveChannels;
            data=obj.Data;
           
        end
        function newobj = getDownSampled(obj, newRate, newFolder)
            if nargin>2
            else
                newFolder=fileparts(obj.Filepath);
            end
            ticd=obj.TimeIntervalCombined;
            currentRate=ticd.getSampleRate;
            probe=obj.Probe;
            chans=probe.getActiveChannels;
            numberOfChannels=numel(chans);
            currentFileName=obj.Filepath;
            [~,name,~]=fileparts(currentFileName);
            ext='.lfp';
            newFileName=fullfile(newFolder,...
                sprintf('%s',name),...
                sprintf('%s%s',name,ext));
            [folder1,name,~]=fileparts(newFileName);
            if ~exist(folder1,'dir'), mkdir(folder1);end
            probe.saveProbeTable(fullfile(folder1,[name '.Probe.mat']));
            ticd=ticd.getDownsampled(currentRate/newRate);
            save(fullfile(folder1,[name '.TimeIntervalCombined.mat']),'ticd');
            probe.createXMLFile(fullfile(folder1,[name '.xml']),newRate);
            if ~exist(newFileName,'file')
                % preprocess it
                system(sprintf('process_resample -f %d,%d -n %d %s %s',...
                    currentRate, newRate, numberOfChannels,...
                    currentFileName, newFileName));
            end
            newobj=ChannelTimeData(newFileName);
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
    end
end