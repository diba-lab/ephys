classdef Oscillation < neuro.basic.TimeSeries
    %OSCILLATION Summary of this class goes here
    %   Detailed explanation goes here
    properties (Access=public)

    end
    methods
        function obj = Oscillation(values, sampleRate)
            %OSCILLATION Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                obj.SampleRate=sampleRate;
                sz=size(values);
                if sz(1)>sz(2)
                    values=values';
                end
                if ~isa(values,'double')
                    obj.Values=double(values);
                else
                    obj.Values=values;
                end
            end
        end
        function timeFrequencyMap = getTimeFrequencyMap(obj,...
                timeFrequencyMethod)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            try
                [ticd1, res]=obj.getTimeIntervalCombined.getDownsampled(...
                    obj.getTimeIntervalCombined.getSampleRate*...
                    timeFrequencyMethod.movingWindow(2));
                obj.Values(end-res+1:end)=[];
            catch
                ticd1=obj.getTimeIntervalCombined;
            end
            timeFrequencyMap=timeFrequencyMethod.execute(...
                obj.Values, obj.getSampleRate);
            timeFrequencyMap=timeFrequencyMap.setTimeintervalCombined(ticd1);
        end
        function ps=getPSpectrum(obj)
            [pxx,f] = pspectrum(double(obj.Values),obj.getSampleRate,...
                'FrequencyLimits',[1 250]);
            ps=neuro.power.PowerSpectrum(pxx,f);
        end

        function ps=getPSpectrumChronux(obj)
            %             params.tapers=[3 5];
            params.Fs=obj.getSampleRate;
            params.fpass=[1 40];
            [S,f] = mtspectrumc( obj.Values, params );
            ps=neuro.power.PowerSpectrum(S,f);
        end
        function ps=getPSpectrumWelch(osc)
            window=2*osc.getSampleRate;
            overlap=round(window/2);
            [psd, freqs] = pwelch(osc.Values, window, overlap,[], ...
                osc.getSampleRate);
            ps=neuro.power.PowerSpectrum(psd,freqs);
        end
        function specslope=getPSpectrumSlope(osc)
            LFP.data=osc.Values;
            LFP.timestamps=osc.getTimeStamps;
            LFP.samplingRate=osc.getSampleRate;
            [specslope,~] = bz_PowerSpectrumSlope(LFP,3,1,...
                'frange',[4 250],'nfreqs',250,'showfig',false);
        end
        function obj=getWhitened_Obsolete(obj, fraquencyRange)
            Fs=obj.SampleRate;
            x=obj.Values;
            x_detrended=detrend(x);
            if nargin>1
                x_whitened = whitening(x_detrended', Fs, 'freq', fraquencyRange);
            else
                x_whitened = whitening(x_detrended', Fs);
            end
            obj.Values=x_whitened';
        end
        function obj=getWhitened(obj)
            obj.Values = reshape(external.WhitenSignal(obj.Values,[],1), ...
                size(obj.Values));
        end
        function obj=getHilbertPhase(obj)
            obj.Values = angle(hilbert(double(obj.Values)));
        end
        function obj=getHilbertPhaseKamran(obj,n)
            %HILBERT  Discrete-time analytic signal via Hilbert transform.
            %   X = HILBERT(Xr) computes the so-called discrete-time analytic signal
            %   X = Xr + i*Xi such that Xi is the Hilbert transform of real vector Xr.
            %   If the input Xr is complex, then only the real part is used: Xr=real(Xr).
            %   If Xr is a matrix, then HILBERT operates along the columns of Xr.
            %
            %   HILBERT(Xr,N) computes the N-point Hilbert transform.  Xr is padded with
            %   zeros if it has less than N points, and truncated if it has more.
            %
            %   For a discrete-time analytic signal X, the last half of fft(X) is zero,
            %   and the first (DC) and center (Nyquist) elements of fft(X) are purely real.
            %
            %   Example:
            %     Xr = [1 2 3 4];
            %     X = hilbert(Xr)
            %   produces X=[1+1i 2-1i 3-1i 4+1i] such that Xi=imag(X)=[1 -1 -1 1] is the
            %   Hilbert transform of Xr, and Xr=real(X)=[1 2 3 4].  Note that the last half
            %   of fft(X)=[10 -4+4i -2 0] is zero (in this example, the last half is just
            %   the last element).  Also note that the DC and Nyquist elements of fft(X)
            %   (10 and -2) are purely real.
            %
            %   See also FFT, IFFT.


            %   References:
            %     [1] Alan V. Oppenheim and Ronald W. Schafer, Discrete-Time
            %     Signal Processing, 2nd ed., Prentice-Hall, Upper Saddle River,
            %     New Jersey, 1998.
            %
            %     [2] S. Lawrence Marple, Jr., Computing the discrete-time analytic
            %     signal via FFT, IEEE Transactions on Signal Processing, Vol. 47,
            %     No. 9, September 1999, pp.2600--2603.
            xr=double(obj.Values);
            if nargin<2, n=[]; end
            if ~isreal(xr)
                warning('HILBERT ignores imaginary part of input.')
                xr = real(xr);
            end
            % Work along the first nonsingleton dimension
            [xr,nshifts] = shiftdim(xr);
            if isempty(n)
                n = size(xr,1);
            end
            x = fft(xr,n,1); % n-point FFT over columns.
            h  = zeros(n,~isempty(x)); % nx1 for nonempty. 0x0 for empty.
            if n>0 & 2*fix(n/2)==n
                % even and nonempty
                h([1 n/2+1]) = 1;
                h(2:n/2) = 2;
            elseif n>0
                % odd and nonempty
                h(1) = 1;
                h(2:(n+1)/2) = 2;
            end
            x = ifft(x.*h(:,ones(1,size(x,2))));

            % Convert back to the original shape.
            x = shiftdim(x,-nshifts);

            obj.Values = angle(x);
        end
        function obj=getLowpassFiltered(obj,filterFreq)
            obj.Values=ft_preproc_lowpassfilter(...
                obj.Values,obj.SampleRate,filterFreq);
        end
        function obj=getHighpassFiltered(obj,filterFreqBand)
            obj.Values=ft_preproc_highpassfilter(...
                obj.Values,obj.SampleRate,filterFreqBand,[],[],[]);
        end
        function obj=getBandpassFiltered(obj,filterFreqBand)
            obj1=obj;
            ft_defaults;
            obj.Values=ft_preproc_bandpassfilter(...
                obj.Values,obj.SampleRate,filterFreqBand,[],[],[]);
            obj=neuro.basic.ChannelProcessed(obj);
            obj.parent=obj1;
            obj.processingInfo.BandpassFilterFreq=filterFreqBand;
        end
        function obj=getEnvelope(obj)
            obj.Values=ft_preproc_hilbert(obj.Values,'abs');
        end
        function samples=subsindex(obj,s)
            error(['This function is changed. Make sure it is working' ...
                ' properly, then move.'])
            idx=s.subs{:};
            vals=obj.Values;
            if isdatetime(s)
                ti=obj.getTimeInterval;
                idx=ti.getSampleFor(idx);
            end
            for iidx=1:numel(idx)
                id=idx(iidx);
                samples(iidx)=vals(id);
            end
        end
    end
    methods
        function va=getVoltageArray(obj)
            warning('Obsolete. Use getValues()')
            va = obj.Values;
        end
        function obj=setVoltageArray(obj,va)
            warning('Obsolete. Use setValues()')
            obj.Values=va;
        end

    end
end

