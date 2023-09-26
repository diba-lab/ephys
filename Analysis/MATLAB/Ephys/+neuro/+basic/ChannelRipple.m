classdef ChannelRipple<neuro.basic.Channel
    %CHANNELTHETA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        RippleEvents
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
        
        function obj = getRippleEventWindowsOnly(obj)
            rips=obj.RippleEvents;
            tbl=rips.getZtAdjustedTbl;
            tw_interest=time.ZT([tbl.start tbl.stop]);
            obj=obj.getTimeWindow(tw_interest);
        end
        function obj = getRippleEventTableWithSignal(obj)
            rips=obj.RippleEvents;
            tbl=rips.getZtAdjustedTbl;
            signal_ripple=neuro.basic.ChannelRipple.empty(height(tbl),0);
            for iripple=1:height(tbl)
                tw_interest=time.ZT([tbl(iripple,:).start tbl(iripple,:).stop]);
                signal_ripple(iripple)=obj.getTimeWindow(tw_interest);
            end
            signal_ripple_tbl=array2table(signal_ripple,VariableNames={'Signal'});
            tbl=[tbl signal_ripple_tbl];
        end
        function chfreq = getFilteredInRippleFrequency(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            chfreq=obj.getBandpassFiltered([120 500]);
        end
        function [freq, tfm] = getFrequencyRippleInstantaneous(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            [freq, tfm]=obj.getFrequencyBandPeakWavelet([100 500]);
        end
        function [] = plotRipples(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            rp=obj.RippleEvents;
            rp.plotWindowsTimeZt
        end

        function ps=getPSpectrumWelch(obj)
            ps=obj.getPSpectrumWelch@neuro.basic.Oscillation();
            ps=neuro.power.PowerSpectrumRipple(ps);
        end
        function ps=getPSpectrumChronux(obj,freq,tapers)
            ps=obj.getPSpectrumChronux@neuro.basic.Oscillation(freq,tapers);
            ps=neuro.power.PowerSpectrumRipple(ps);
        end
        function ps=getPSpectrum(obj,freq)
            ps=obj.getPSpectrum@neuro.basic.Oscillation(freq);
            ps=neuro.power.PowerSpectrumRipple(ps);
        end
        
    end
end

