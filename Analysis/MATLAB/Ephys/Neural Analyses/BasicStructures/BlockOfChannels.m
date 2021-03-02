classdef BlockOfChannels
    %BLOCKOFCHANNELS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Channels
    end
    
    methods
        function obj = BlockOfChannels(channels)
            %BLOCKOFCHANNELS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Channels=CellArrayList;
            try
                for ichan=1:numel(channels)
                    obj.addChannel(channels{ichan})
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
        function obj = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            chs=obj.Channels;
            iter=chs.createIterator;
            i=1;
            colors=linspecer(chs.length/2,'sequential');
            while iter.hasNext
                ch=iter.next;
                if mod(i,2)==1
                    ch=ch.getMedianFiltered(seconds(minutes(1)));
                    ch=ch.getMeanFiltered(seconds(minutes(1)));
                    p1=ch.plot();hold on;
                    p1.Color=colors((i+1)/2,:);
                    p1.LineWidth=2;
                end
                i=i+1;
            end
        end
    end
end

