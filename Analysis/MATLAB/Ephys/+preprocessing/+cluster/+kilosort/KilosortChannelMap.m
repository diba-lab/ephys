classdef KilosortChannelMap
    %KILOSORTCONFIG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Probe
        SamplingRate
    end
    
    methods
        function obj = KilosortChannelMap(probe,SamplingRate)
            %KILOSORTCONFIG Construct an instance of this class
            %   Detailed explanation goes here
            obj.Probe=probe;
            obj.SamplingRate=SamplingRate;
        end
        
        function [] = createChannelMapFile(obj,file)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %  create a channel map file
            probe=obj.Probe;
            chans=probe.getActiveChannels;
            t1=probe.getSiteSpatialLayout(chans);
            Nchannels = numel(chans);
            connected = true(Nchannels, 1);
            chanMap   = 1:Nchannels;
            chanMap0ind = chanMap - 1;
            xcoords   = t1.X;
            ycoords   = t1.Z;
            kcoords   = ones(Nchannels,1); % grouping of channels (i.e. tetrode groups)
            
            fs = obj.SamplingRate; % sampling frequency
            save(file, ...
                'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')
            %%
            
            % kcoords is used to forcefully restrict templates to channels in the same
            % channel group. An option can be set in the master_file to allow a fraction
            % of all templates to span more channel groups, so that they can capture shared
            % noise across all channels. This option is
            
            % ops.criterionNoiseChannels = 0.2;
            
            % if this number is less than 1, it will be treated as a fraction of the total number of clusters
            
            % if this number is larger than 1, it will be treated as the "effective
            % number" of channel groups at which to set the threshold. So if a template
            % occupies more than this many channel groups, it will not be restricted to
            % a single channel group.
        end
    end
end

