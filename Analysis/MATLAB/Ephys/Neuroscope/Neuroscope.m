classdef (Abstract) Neuroscope
    %NEUROSCOPEFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        nBits=16;
        nChannels;
        samplingRate1=30000;
        voltageRange=20;
        amplification=1000;
        offset=0;
        lfpSamplingRate;
        extension='lfp';
        samplingRate2;
        screenGain=.2;
    end
    
    methods (Abstract)
    end
    methods
        function [] = createXMLFile(obj,filepath,samplingRate)
            obj.samplingRate2=samplingRate;
            obj.lfpSamplingRate=samplingRate;
            channels=obj.getActiveChannels;
            obj.nChannels=numel(channels);
            s.parameters.Attributes.version='1.0';
            s.parameters.Attributes.creator='neuroscope-2.0.0 by utku';
            s.parameters.acquisitionSystem.nBits.Text=num2str(obj.nBits);
            s.parameters.acquisitionSystem.nChannels.Text=num2str(obj.nChannels);
            s.parameters.acquisitionSystem.samplingRate.Text=num2str(obj.samplingRate1);
            s.parameters.acquisitionSystem.voltageRange.Text=num2str(obj.voltageRange);
            s.parameters.acquisitionSystem.amplification.Text=num2str(obj.amplification);
            s.parameters.acquisitionSystem.offset.Text=num2str(obj.offset);
            s.parameters.fieldPotentials.lfpSamplingRate.Text=num2str(obj.lfpSamplingRate);
            s.parameters.files.file.extension.Text=obj.extension;
            s.parameters.files.file.samplingRate.Text=num2str(obj.samplingRate2);
            lay=obj.getSiteSpatialLayout;
            shanks=unique(lay.ShankNumber(lay.isActive==1));
%             xVals=obj.getXvalsofShanks(shanks)
            for ishank=1:numel(shanks)
                chans=lay.ChannelNumberComingOutPreAmp(lay.isActive==1&lay.ShankNumber==shanks(ishank));
                for ichan=1:numel(chans)
                    chan1=chans(ichan);
                    chan=find(channels==chan1);
                    s.parameters.anatomicalDescription.channelGroups...
                        .group{ishank}.channel{ichan}.Attributes.skip='0';
                    s.parameters.anatomicalDescription.channelGroups...
                        .group{ishank}.channel{ichan}.Text=num2str(chan-1);
                end
            end
            s.parameters.spikeDetection='';
            s.parameters.neuroscope.Attributes.version='2.0.0';
            s.parameters.neuroscope.miscellaneous.screenGain.Text=num2str(obj.screenGain);
            s.parameters.neuroscope.miscellaneous.traceBackgroundImage.Text='';
            s.parameters.neuroscope.video.rotate.Text=num2str(0);
            s.parameters.neuroscope.video.flip.Text=num2str(0);
            s.parameters.neuroscope.video.videoImage.Text='';
            s.parameters.neuroscope.video.positionsBackground.Text=num2str(0);
            s.parameters.neuroscope.spikes.nSamples.Text=num2str(32);
            s.parameters.neuroscope.spikes.peakSampleIndex.Text=num2str(16);
            chansordered=sort(channels);
            lineStyles = linspecer(numel(unique(lay.ShankNumber)),'qualitative');
            for ichan=1:numel(chansordered)
                chan1=chansordered(ichan);
                chan=find(channels==chan1);

                shank=lay.ShankNumber(lay.ChannelNumberComingOutPreAmp==chan1);
                s.parameters.neuroscope.channels.channelColors{ichan}.channel.Text=num2str(chan-1);
                hexcolor=lower( rgb2hex(lineStyles(shank,:)));
                s.parameters.neuroscope.channels.channelColors{ichan}.color.Text=hexcolor;
                s.parameters.neuroscope.channels.channelColors{ichan}.anatomyColor.Text=hexcolor;
                hexcolor=lower( rgb2hex(lineStyles(shank,:)/2));
                s.parameters.neuroscope.channels.channelColors{ichan}.spikeColor.Text=hexcolor;
                s.parameters.neuroscope.channels.channelOffset{ichan}.channel.Text=num2str(chan-1);
                s.parameters.neuroscope.channels.channelOffset{ichan}.defaultOffset.Text=num2str(0);
            end
            
            [path,name,~]=fileparts(filepath);
            if isfile(fullfile(path,strcat(name,'.nrs'))), delete(fullfile(path,strcat(name,'.nrs'))); end
            struct2xml(s,filepath); 
        end
        function [] = createXMLFileNotOrder(obj,filepath,samplingRate)
            obj.samplingRate2=samplingRate;
            obj.lfpSamplingRate=samplingRate;
            channels=obj.getActiveChannels;
            obj.nChannels=numel(channels);
            s.parameters.Attributes.version='1.0';
            s.parameters.Attributes.creator='neuroscope-2.0.0 by utku';
            s.parameters.acquisitionSystem.nBits.Text=num2str(obj.nBits);
            s.parameters.acquisitionSystem.nChannels.Text=num2str(obj.nChannels);
            s.parameters.acquisitionSystem.samplingRate.Text=num2str(obj.samplingRate1);
            s.parameters.acquisitionSystem.voltageRange.Text=num2str(obj.voltageRange);
            s.parameters.acquisitionSystem.amplification.Text=num2str(obj.amplification);
            s.parameters.acquisitionSystem.offset.Text=num2str(obj.offset);
            s.parameters.fieldPotentials.lfpSamplingRate.Text=num2str(obj.lfpSamplingRate);
            s.parameters.files.file.extension.Text=obj.extension;
            s.parameters.files.file.samplingRate.Text=num2str(obj.samplingRate2);
            lay=obj.getSiteSpatialLayout;
            shanks=unique(lay.ShankNumber(lay.isActive==1));
%             xVals=obj.getXvalsofShanks(shanks)
            for ishank=1:numel(shanks)
                chans=lay.ChannelNumberComingOutPreAmp(lay.isActive==1&lay.ShankNumber==shanks(ishank));
                for ichan=1:numel(chans)
                    chan1=chans(ichan);
%                     chan=find(channels==chan1);
                    s.parameters.anatomicalDescription.channelGroups...
                        .group{ishank}.channel{ichan}.Attributes.skip='0';
                    s.parameters.anatomicalDescription.channelGroups...
                        .group{ishank}.channel{ichan}.Text=num2str(chan1-1);
                end
            end
            s.parameters.spikeDetection='';
            s.parameters.neuroscope.Attributes.version='2.0.0';
            s.parameters.neuroscope.miscellaneous.screenGain.Text=num2str(obj.screenGain);
            s.parameters.neuroscope.miscellaneous.traceBackgroundImage.Text='';
            s.parameters.neuroscope.video.rotate.Text=num2str(0);
            s.parameters.neuroscope.video.flip.Text=num2str(0);
            s.parameters.neuroscope.video.videoImage.Text='';
            s.parameters.neuroscope.video.positionsBackground.Text=num2str(0);
            s.parameters.neuroscope.spikes.nSamples.Text=num2str(32);
            s.parameters.neuroscope.spikes.peakSampleIndex.Text=num2str(16);
            chansordered=sort(channels);
            lineStyles = linspecer(numel(unique(lay.ShankNumber)),'qualitative');
            for ichan=1:numel(channels)
                chan1=channels(ichan);
                chan=find(channels==chan1);

                shank=lay.ShankNumber(lay.ChannelNumberComingOutPreAmp==chan1);
                s.parameters.neuroscope.channels.channelColors{ichan}.channel.Text=num2str(chan1-1);
                hexcolor=lower( rgb2hex(lineStyles(shank,:)));
                s.parameters.neuroscope.channels.channelColors{ichan}.color.Text=hexcolor;
                s.parameters.neuroscope.channels.channelColors{ichan}.anatomyColor.Text=hexcolor;
                hexcolor=lower( rgb2hex(lineStyles(shank,:)/2));
                s.parameters.neuroscope.channels.channelColors{ichan}.spikeColor.Text=hexcolor;
                s.parameters.neuroscope.channels.channelOffset{ichan}.channel.Text=num2str(chan1-1);
                s.parameters.neuroscope.channels.channelOffset{ichan}.defaultOffset.Text=num2str(0);
            end
            
            [path,name,~]=fileparts(filepath);
            if isfile(fullfile(path,strcat(name,'.nrs'))), delete(fullfile(path,strcat(name,'.nrs'))); end
            struct2xml(s,filepath); 
        end
    end
    methods(Access=private)
        function xVals=getXvalsofShanks(obj,shanks)
            lay=obj.getSiteSpatialLayout;
            for ishank=1:numel(shanks)
                shank=shanks(ishank);
                xVals(ishank)= mean(lay.X( lay.ShankNumber==shank&lay.isActive==1));
            end
            
        end
        
    end
end