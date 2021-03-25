classdef BlockOfChannels
    %BLOCKOFCHANNELS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Name
        Channels
        Hypnogram
        Info
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
            chan=chan.setInfo(obj.Info);
            channels.add(chan);
            obj.Channels=channels;
        end
        function obj = addHypnogram(obj,hyp)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            try
                hyp=hyp.getWindow([obj.getStartTime obj.getEndTime]);
            catch
            end
            obj.Hypnogram=hyp;
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
            newboc.Info=obj.Info;
        end
        function [axplot,axhyp,ps] = plot(obj,axplot,axhyp,ch)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            chs=obj.Channels;
            if exist('ch','var')&&~isempty(ch)
                idx=ch;
            else
                idx=1:chs.length;
            end
            colors=hsv2rgb([50/360*ones(1,5);linspace(0.5,1,5);linspace(0.5,1,5)]');
            mua_int=linspecer(2);
            colors=[colors;mua_int];
            if exist('axplot','var')&&~isempty(axplot), axes(axplot);end
            i=1;
            for ich=idx
                ch=chs.get(ich);
                ch=ch.getMedianFiltered(seconds(minutes(1)));
                ch=ch.getMeanFiltered(seconds(minutes(1)));
                p1=ch.plot();hold on;
                p1.Color=colors(i,:);
                p1.LineWidth=2;
                ps(i)=p1; %#ok<AGROW>
                i=i+1;
            end
            hyp=obj.getHypnogram;
            if ~exist('axhyp','var')||isempty(axhyp)
                axplot=gca;
                axhyp=axes;
                axhyp.Position=[axplot.Position(1) axplot.Position(2)+axplot.Position(4) axplot.Position(3) axplot.Position(4)/10];
            else
                axes(axhyp);hold on;
            end
            hyp.plot;
        end
        function sr=getStateRatios(obj,winsize,a,edges)
            ss=obj.getHypnogram;
            sr=ss.getStateRatios(winsize,a,edges);
        end
        function [episode, theEpisodeAbs]=getState(obj,state)
            ss=obj.getHypnogram;
            try
            theEpisodeAbs=ss.getState(state);
            catch
            end
            if ~isempty(theEpisodeAbs)
                ch=obj.getChannel(1);
                episode=ch.getTimeWindow(theEpisodeAbs);
                obj.Info.State=state;
                episode=episode.setInfo(obj.Info);
            else
                episode=[];
            end
        end
        function dt=getDate(obj)
            dt=obj.Channels.get(1).getTimeInterval.getDate;
        end
        function ch=getChannel(obj,ch)
            if exist('ch','var')&&~isempty(ch)
                ch=obj.Channels.get(ch);
            else
                ch=obj.Channels.get(1);
            end
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
        function obj=setName(obj,n)
            obj.Name=n;
        end
        function n=getName(obj)
            n=obj.Name;
        end
    end
end

