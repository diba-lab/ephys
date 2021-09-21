classdef SpikeArraySleepDeprivation<neuro.spike.SpikeArray
    %SPIKEARRAYSLEEPDEPRIVATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Session
    end
    
    methods
        function obj = SpikeArraySleepDeprivation(spikeArray,session)
            %SPIKEARRAYSLEEPDEPRIVATION Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@neuro.spike.SpikeArray(spikeArray);
            obj.Session = session;
        end
        
        function sabl = getBlock(obj, blockName)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            bltime=obj.Session.Blocks.get(blockName);
            sa=obj.getTimeInterval(bltime);
            sabl=experiment.SpikeArraySleepDeprivationBlock(sa, blockName, bltime);
        end
        function sa=getSpikeArray(obj)
            sa=neuro.spike.SpikeArray(obj);
        end
    end
end

