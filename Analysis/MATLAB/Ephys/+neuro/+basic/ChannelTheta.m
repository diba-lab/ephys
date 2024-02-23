classdef ChannelTheta<neuro.basic.Channel
    %CHANNELTHETA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = ChannelTheta(varargin)
            %CHANNELTHETA Construct an instance of this class
            %   Detailed explanation goes here
            chan=varargin{1};
            fnames=fieldnames(chan);
            for ifn=1:numel(fnames)
                obj.(fnames{ifn})=chan.(fnames{ifn});
            end
        end
        
        function freq = getFrequencyThetaInstantaneous(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            freq=obj.getFrequencyBandPeakWavelet([5 10]);
        end

        function ps=getPSpectrumWelch(obj)
            ps=obj.getPSpectrumWelch@neuro.basic.Oscillation();
            ps=neuro.power.PowerSpectrumTheta(ps);
        end
        function ps=getPSpectrumChronux(obj)
            ps=obj.getPSpectrumChronux@neuro.basic.Oscillation();
            ps=neuro.power.PowerSpectrumTheta(ps);
        end
        function ps=getPSpectrum(obj)
            ps=obj.getPSpectrum@neuro.basic.Oscillation();
            ps=neuro.power.PowerSpectrumTheta(ps);
        end

    end
end

