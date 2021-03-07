classdef BlockOfChannels
    %BLOCKOFCHANNELS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Channels
        Hypnogram
    end
    
    methods
        function obj = BlockOfChannels(channels)
            %BLOCKOFCHANNELS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Channels=CellArrayList;
            try
                for ichan=1:numel(channels)
                    obj=obj.addChannel(channels{ichan});
                end
            catch
            end
        end
        
        function obj = addChannel(obj,chan)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            channels=obj.Channels;
            channels.add(chan);
            obj.Channels=channels;
        end
        function obj = addHypnogram(obj,hyp)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            hyp1=hyp.getWindow([obj.getStartTime obj.getEndTime]);
            obj.Hypnogram=hyp1;
        end
        function newboc = getWindow(obj,window)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            channels=obj.Channels;
            newboc=BlockOfChannels();
            iter=channels.createIterator;
            while iter.hasNext
                chan1=iter.next;
                chan=chan1.getTimeWindow(window);
                newboc=newboc.addChannel(chan);
            end
            hyp=obj.getHypnogram;
            try
                hyp1=hyp.getWindow(window);
                newboc=newboc.addHypnogram(hyp1);
            catch
            end
        end
        function [axplot,axhyp,ps] = plot(obj,axplot,axhyp)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            chs=obj.Channels;
            iter=chs.createIterator;
            i=1;
            colors=linspecer(chs.length/2,'sequential');
            if exist('axplot','var'), axes(axplot);end
            while iter.hasNext
                ch=iter.next;
                if mod(i,2)==1
                    ch=ch.getMedianFiltered(seconds(minutes(1)));
                    ch=ch.getMeanFiltered(seconds(minutes(1)));
                    p1=ch.plot();hold on;
                    p1.Color=colors((i+1)/2,:);
                    p1.LineWidth=2;
                    ps((i+1)/2)=p1; %#ok<AGROW>
                end
                i=i+1;
            end
            hyp=obj.getHypnogram;
            if ~exist('axhyp','var')
                axplot=gca;
                axhyp=axes;
                axhyp.Position=[axplot.Position(1) axplot.Position(2)+axplot.Position(4) axplot.Position(3) axplot.Position(4)/10];
            else
                axes(axhyp);hold on;
            end
            hyp.plot;
        end
        function dt=getDate(obj)
            dt=obj.Channels.get(1).getTimeInterval.getDate;
        end
        function dt=getStartTime(obj)
            dt=obj.Channels.get(1).getTimeInterval.getStartTime;
        end
        function dt=getEndTime(obj)
            dt=obj.Channels.get(1).getTimeInterval.getEndTime;
        end
        function hp=getHypnogram(obj)
            hp=obj.Hypnogram;
        end
    end
end

