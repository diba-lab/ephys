classdef RippleTable
    %RIPPLETABLE Summary of this class goes here
    %   Detailed explanation goes here
    properties
        Table
    end
    methods
        function obj = RippleTable(table)
            %RIPPLETABLE Construct an instance of this class
            %   Detailed explanation goes here
            obj.Table = table;
        end
        function sess = getSessions(obj)
            sess = unique(obj.Table.Session);
        end
        function obj = getSession(obj,sesno)
            obj.Table=obj.Table(obj.Table.Session==sesno,:);
        end
        function obj = getTimeWindow(obj,tw)
            obj.Table=obj.Table(obj.Table.peak>tw(1)&obj.Table.peak<tw(2),:);
        end
        function sig = getMergedSignal(obj)
            % sr=obj.Table.Signal(1).getSampleRate;
            sig=neuro.basic.Oscillation([obj.Table.Signal.Values],1250);
        end
        function obj = removeArtifacts(obj)
            obj.Table=obj.Table( ...
                ~(obj.Table.frequency_wavelet==max(obj.Table.frequency_wavelet)|...
                obj.Table.frequency_wavelet==min(obj.Table.frequency_wavelet))...
                ,:);
        end
        function obj = plotScatter(obj,y,sz)
            x=hours(obj.Table.peak);
            y=obj.Table.(y);
            size=obj.Table.(sz);
            scatter(x,y,size/10,"filled",MarkerFaceAlpha=.2);
        end
        function obj = plotRunningAverage(obj,y,winrange,winsize,winstep)
            [y,x]=obj.getRunningAverage(y,winrange,winsize,winstep);
            plot(x,y);
        end
        function [y1,x] = getRunningAverage(obj,y,winrange,winsize,winstep)
            winranger=hours(round(hours(winrange)*20)/20);
            winstart=winranger(1):winstep:(winranger(2)-winsize);
            winstop=winstart+winsize;
            wincenter=winstart+winsize/2;
            x=hours(wincenter);
            y1=nan(size(x));
            for iw=1:numel(wincenter)
                win=[winstart(iw) winstop(iw)];
                w1=obj.getTimeWindow(win);
                y1(iw)=mean(w1.Table.(y),"omitmissing");
            end
        end
        function runningWindowRipple = getRunningWindows(obj,s_ratios)
            runningWindowRipple=[];
            for iwin=1:height(s_ratios)
                win1=s_ratios(iwin,:);
                tbl=obj.getTimeWindow([win1.ZTStart win1.ZTEnd]);
                sig1=tbl.getMergedSignal;
                if sig1.getLength>seconds(2)
                    freq=[40 500];
                    sig.p_welch=sig1.getPSpectrumWelch;
                    % p_welch_fooof=p_welch.getFooof;
                    % p_welch_fooof.plot
                    sig.p_ps=sig1.getPSpectrum(freq);
                    % p_ps_fooof=p_ps.getFooof;
                    % p_ps_fooof.plot
                    sig.p_ch=sig1.getPSpectrumChronux(freq,[3 5]);
                    % p_ch_fooof=p_ch.getFooof;
                    % p_ch_fooof.plot
                    % sig_combined.getFrequencyBandPeakWavelet([100 500])
                    % pk=p_welch_fooof.getPeak([5 10]);
                else
                    sig.p_welch=neuro.power.PowerSpectrum;
                    sig.p_ps=neuro.power.PowerSpectrum;
                    sig.p_ch=neuro.power.PowerSpectrum;
                end
                tbl_ses=[win1(:,{'Session','Condition','ZTStart', ...
                    'ZTCenter','ZTEnd'}) struct2table(sig)];
                runningWindowRipple=[runningWindowRipple; tbl_ses];
            end
        end
    end
end