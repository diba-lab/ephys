classdef SpikeArraySleepDeprivationBlock < experiment.SpikeArraySleepDeprivation
    %SPIKEARRAYSLEEPDEPRIVATIONBLOCK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        BlockName
        BlockTime
    end
    
    methods
        function obj = SpikeArraySleepDeprivationBlock(sa, blockName, bltime)
            %SPIKEARRAYSLEEPDEPRIVATIONBLOCK Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@experiment.SpikeArraySleepDeprivation(sa.getSpikeArray,sa.Session);
            obj.BlockName=blockName;
            obj.BlockTime=bltime;
        end
        
        function sa = getTimeFrameRelativeToBeginAndEndInDurations(obj, duration)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for idur=1:numel(duration)
                dur1=duration(idur);
                if dur1>0
                    timeFrame(idur)=obj.BlockTime(1)+dur1;
                elseif dur1<0
                    timeFrame(idur)=obj.BlockTime(2)+dur1;
                elseif mean(duration)>0
                    timeFrame(idur)=obj.BlockTime(1)+dur1;
                elseif mean(duration)<0
                    timeFrame(idur)=obj.BlockTime(2)+dur1;
                end
            end
            sa=obj.getTimeInterval(timeFrame);
        end
    end
end

