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
        function tbl = getRippleEventTableWithSignal(obj)
            rips=obj.RippleEvents;
            tbl=rips.getZtAdjustedTbl;
            signal_ripple=neuro.basic.Channel.empty(height(tbl),0);
            for iripple=1:height(tbl)
                tw_interest=time.ZT([tbl(iripple,:).start tbl(iripple,:).stop]);
                s1=obj.getTimeWindow(tw_interest);
                signal_ripple(iripple)=neuro.basic.Channel( ...
                    s1.ChannelName,s1.getValues,s1.TimeIntervalCombined);
            end
            size_array=size(signal_ripple);
            if size_array(1)<size_array(2)
                signal_ripple=signal_ripple';
            end
            signal_ripple_tbl=array2table(signal_ripple,VariableNames={'Signal'});
            tbl=[tbl signal_ripple_tbl];
        end
        function tbl = getRippleEventPropertiesTable(obj)
            rips=obj.RippleEvents;
            obj.TimeIntervalCombined=obj.TimeIntervalCombined.setTimeIntervalIndex;
            tbl=rips.getZtAdjustedTbl;
            signal_ripple=neuro.basic.ChannelRipple.empty(height(tbl),0);
            for iripple=1:height(tbl)
                tw_interest=time.ZT([tbl(iripple,:).start tbl(iripple,:).stop]);
                signal_ripple(iripple)=obj.getTimeWindow(tw_interest);
            end
            signal_ripple_tbl=array2table(signal_ripple,VariableNames={'Signal'});
            tbl=[tbl signal_ripple_tbl];
        end
        function obj = getTimeWindow(obj,window)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj=obj.getTimeWindow@neuro.basic.Channel(window);
            obj.RippleEvents=obj.RippleEvents.getWindow(window);
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
        function [] = plotVisualize(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            frange=[100 250];
            tiledlayout(5,5,"TileSpacing","tight")
            raw=nexttile([1, 4]);
            tf=nexttile(6,[3 4]);
            f=nexttile(10,[3 1]);
            t=nexttile(21,[1 4]);
            linkaxes([raw,tf,t],'x')
            axes(raw);
            obj.plot;
            yyaxis("right");
            bp=obj.getBandpassFiltered(frange);
            bp.plot;hold on;
            env=bp.getEnvelope;
            env.plot;hold on;
            envi=-env;envi.plot;
            m1=obj.getWhitened.getTimeFrequencyMap(frange);
            m1=obj.getTimeFrequencyMap(frange);
            axes(tf);m1.plot;hold on
            sz=size(m1.matrix);
            mat=abs(m1.matrix);
            [row,col]=ind2sub(sz, find(imregionalmax(mat)));
            vals=mat(find(imregionalmax(mat)));
            [a,b]=sort(vals,"descend");
            tps=hours(obj.TimeIntervalCombined.getTimePointsZT);
            pt=tps(col(b(1)));
            pf=m1.frequencyPoints(row(b(1)));
            scatter(pt,pf)
            axes(t);
            ts=obj;
            ts.Values=mat(row(b(1)),:)';
            ts.plot;
            fs=mat(:,col(b(1)));
            axes(f)
            plot(m1.frequencyPoints,fs);
            f.XLim=frange;
            f.View=[90 270];
        end
        function tbl = getProperties(obj)
            % Define frequency ranges
            frangecount = [120 200];
            frangewavelet = [100 250];

            % Get bandpass filtered signals and envelopes
            bp_count = obj.getBandpassFiltered(frangecount);
            env_count = bp_count.getEnvelope;

            bp_wavelet = obj.getBandpassFiltered(frangewavelet);
            env_wavelet = bp_wavelet.getEnvelope;

            % Get time-frequency maps
            m1_wavelet = obj.getWhitened.getTimeFrequencyMap(frangewavelet);
            m2_wavelet = obj.getTimeFrequencyMap(frangewavelet);

            % Find regional maxima in the matrix
            mat_wavelet = abs(m1_wavelet.matrix);
            [row, ~] = ind2sub(size(mat_wavelet), find(imregionalmax(mat_wavelet)));
            vals = mat_wavelet(imregionalmax(mat_wavelet));
            [~, b] = sort(vals, 'descend');

            mat_wavelet2 = abs(m2_wavelet.matrix);
            [row2, ~] = ind2sub(size(mat_wavelet2), find(imregionalmax(mat_wavelet2)));
            vals2 = mat_wavelet2(imregionalmax(mat_wavelet2));
            [~, b2] = sort(vals2, 'descend');

            % Calculate frequency points
            pf_wavelet = m1_wavelet.frequencyPoints(row(b(1)));
            pf_wavelet_nowhiten = m2_wavelet.frequencyPoints(row2(b2(1)));

            % Create tables for frequency data
            f_w = array2table(pf_wavelet, 'VariableNames', {'frequency_wavelet'});
            f_w2 = array2table(pf_wavelet_nowhiten, 'VariableNames', ...
                {'frequency_wavelet_nowhiten'});

            % Calculate maximum power from envelopes
            p_env = array2table(max(env_count.Values), ...
                'VariableNames', {'power_envelope'});
            p_env2 = array2table(max(env_wavelet.Values), ...
                'VariableNames', {'power_envelope_largefilter'});

            % Get phase signals and find peaks
            ph_count = bp_count.getPhase;
            ph_count2 = bp_wavelet.getPhase;
            pks_count = findpeaks(ph_count.Values);
            pks_count2 = findpeaks(ph_count2.Values);

            % Calculate median frequency counts
            f_ph_count = median(1 ./ (diff(pks_count.loc) / ...
                double(ph_count.getSampleRate)));
            f_ph_count_large = median(1 ./ (diff(pks_count2.loc) / ...
                double(ph_count2.getSampleRate)));

            % Create tables for frequency counts
            f_c = array2table(f_ph_count, 'VariableNames', {'frequency_count'});
            f_c_large = array2table(f_ph_count_large, ...
                'VariableNames', {'frequency_count_large'});

            % Combine all tables into one
            tbl = [f_w, f_w2, p_env, p_env2, f_c, f_c_large];
        end

        function timeFrequencyMap = getTimeFrequencyMap(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            tfmethod=neuro.tf.TimeFrequencyWavelet( ...
                linspace(freq(1),freq(2),diff(freq)*1));
            obj=obj.getWhitened;
            timeFrequencyMap=...
                obj.getTimeFrequencyMap@neuro.basic.Oscillation(tfmethod);
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

