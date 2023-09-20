classdef ChannelRipple<neuro.basic.Channel
    %CHANNELTHETA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = ChannelRipple(varargin)
            %CHANNELTHETA Construct an instance of this class
            %   Detailed explanation goes here
            chan=varargin{1};
            fnames=fieldnames(chan);
            for ifn=1:numel(fnames)
                obj.(fnames{ifn})=chan.(fnames{ifn});
            end
        end
        
        function freq = getFrequencyRippleInstantaneous(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            freq=obj.getFrequencyBandPeakWavelet([120 250]);
        end

        function ps=getPSpectrumWelch(obj)
            ps=obj.getPSpectrumWelch@neuro.basic.Oscillation();
            ps=neuro.power.PowerSpectrumRipple(ps);
        end
        function ps=getPSpectrumChronux(obj)
            ps=obj.getPSpectrumChronux@neuro.basic.Oscillation();
            ps=neuro.power.PowerSpectrumRipple(ps);
        end
        function ps=getPSpectrum(obj)
            ps=obj.getPSpectrum@neuro.basic.Oscillation();
            ps=neuro.power.PowerSpectrumRipple(ps);
        end

    end
end

