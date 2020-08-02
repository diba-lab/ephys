classdef ChannelTimeData
    %COMBINEDCHANNELS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        TimeseriesCollection
    end
    
    methods
        function newObj = ChannelTimeData(sudotscollectiondata)
            newObj.TimeseriesCollection=tscollectiondata;
        end
        
        function newobj = getChannels(obj,channelNames)
            tsc=obj.TimeseriesCollection;
            channels=tsc.gettimeseriesnames;
            try
                [~,Locb]=ismember(channelNames,channels);
            catch
                channels=cell2mat(cellfun(@(x) str2double(x(3:end)),...
                    channels,'UniformOutput',false));
                [~,Locb]=ismember(channelNames,channels);
            end
            channelstoRemove=tsc.gettimeseriesnames;
            channelstoRemove(Locb)=[];
            newtsc=tsc.removets(channelstoRemove);
            newobj=ChannelTimeData(newtsc);
            if numel(Locb)==1
                newobj=Channel(channelNames,...
                    squeeze(newobj.TimeseriesCollection.(channelNames).Data)',...
                    obj.TimeseriesCollection.Time,...
                    obj.TimeseriesCollection.TimeInfo.StartDate);
            end
        end
        function [] = plot(obj,varargin)
            try
                channels=varargin{:};
            catch
                tsc=obj.TimeseriesCollection;
                channels=tsc.gettimeseriesnames;
            end
            hold on
            colors=othercolor('RdBu4',numel(channels))/1.5;
            colors=linspecer(numel(channels),'sequential')/1.5;
            for ichan=1:numel(channels)
                subplot(numel(channels),1,ichan)
                try
                    chname=channels{ichan};
                catch
                    chname=['CH' num2str(channels(ichan))];
                end
                ch=obj.getChannels(chname);
                %                 ch=ch.getHighpassFiltered(1000);
                %                 ch=ch.getLowpassFiltered(50);
                ch.plot('Color',colors(ichan,:));
                ax=gca;
                ax.YLim=[-1000 1000]*10;
                ax.Position=[ax.Position(1)*2.5 ax.Position(2)...
                    ax.Position(3)*.8 ax.Position(4)*5];
                axis off
            end
        end
    end
end