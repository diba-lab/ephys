classdef Oscillation
    %OSCILLATION Summary of this class goes here
    %   Detailed explanation goes here
    properties (Access=public)
        Values
        SampleRate
    end
    methods
        function obj = Oscillation(values, sampleRate)
            %OSCILLATION Construct an instance of this class
            %   Detailed explanation goes here
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
        function p1=plot(obj,varargin)
            ts=obj.getTimeStamps;
            vals=obj.getValues;
            p1=plot(ts,vals,varargin{:});
%             ax=gca;
%             ax.XLim=[ts(1) ts(end)];
        end

        function obj=getDownSampled(obj,newRate)
            rate=obj.SampleRate/newRate;
            obj.Values=downsample(obj.getValues,rate);
            obj.SampleRate=newRate;
            obj=obj.setTimeInterval(obj.getTimeInterval.getDownsampled(rate));
        end
        function obj=getReSampled(obj,sr)    
            obj.Values=resample(obj.getValues, sr,obj.getSampleRate);
            obj.SampleRate=sr;
        end
        function obj=getFillMissing(obj,window)    
            obj.Values=fillmissing(obj.getValues,"movmedian",window*obj.SampleRate);
        end
        function ps=getPSpectrum(obj)
            [pxx,f] = pspectrum(double(obj.Values),obj.getSampleRate,...
                'FrequencyLimits',[1 250]);
            ps=neuro.power.PowerSpectrum(pxx,f);
        end
        function l=getLength(obj)
            l=seconds(obj.getNumberOfPoints/obj.getSampleRate);
        end
        function ps=getPSpectrumChronux(obj)
%             params.tapers=[3 5];
            params.Fs=obj.getSampleRate;
            params.fpass=[1 250];
            [S,f] = mtspectrumc( obj.Values, params );
            ps=neuro.power.PowerSpectrum(S,f);
        end
        function ps=getPSpectrumWelch(osc)
            window=2*osc.getSampleRate;
            overlap=window/2;
            [psd, freqs] = pwelch(osc.Values, window, overlap, [], osc.getSampleRate);
            ps=neuro.power.PowerSpectrum(psd,freqs);
        end
        function specslope=getPSpectrumSlope(osc)
            LFP.data=osc.Values;
            LFP.timestamps=osc.getTimeStamps;
            LFP.samplingRate=osc.getSampleRate;
            [specslope,~] = bz_PowerSpectrumSlope(LFP,3,1,...
                'frange',[4 250],'nfreqs',250,'showfig',false);
        end
        function np=getNumberOfPoints(osc)
            np=numel(osc.Values);
        end
        function ts=getTimeStamps(osc)
            ts=linspace(0, osc.getNumberOfPoints/osc.getSampleRate, osc.getNumberOfPoints);
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
            obj.Values = reshape(external.WhitenSignal(obj.Values,[],1),size(obj.Values));
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
            obj.Values=ft_preproc_bandpassfilter(...
                obj.Values,obj.SampleRate,filterFreqBand,[],[],[]);
        end
        function obj=getEnvelope(obj)
            obj.Values=ft_preproc_hilbert(obj.Values,'abs');
        end
        function obj=getMedianFiltered(obj,windowInSeconds,varargin)
            obj.Values=medfilt1(obj.Values,...
                obj.getSampleRate*windowInSeconds,varargin{:});
        end
        function obj=getMeanFiltered(obj,windowInSeconds)
            obj.Values=smoothdata(obj.Values,...
                'movmean', obj.getSampleRate*windowInSeconds);
        end
        function obj=getZScored(obj)
            obj.Values=zscore(obj.Values);
        end
        function vals=getValues(obj)
            vals = obj.Values;
            if 1~=size(vals,1)
                vals=vals';
            end
        end
        function obj=setValues(obj,va)
            obj.Values=va;
        end
        function time=getSampleRate(obj)
            time = obj.SampleRate;
        end
        function obj=getIdxPoints(obj,idx)
            va = obj.Values;
            obj.Values=va(idx);
        end
        function obj=setSampleRate(obj,newrate)
            obj.SampleRate=newrate;
        end
        function obj=rdivide(obj,num)
            obj=obj.setValues(obj.getValues./num);
        end
        function obj=plus(obj,num)
            obj=obj.setValues(obj.getValues+num);
        end
        function obj=minus(obj,num)
            obj=obj.setValues(obj.getValues-num);
        end
        function obj=times(obj,num)
            obj=obj.setValues(obj.getValues.*num);
        end
        function idx=lt(obj,num)
            idx=obj.getValues<num;
        end
        function idx=gt(obj,num)
            idx=obj.getValues>num;
        end
%         function obj=subsasgn(obj,s,n)
%             va=obj.getValues;
%             va(s.subs{:})=n;
%             obj=obj.setValues(va );
%         end
        function samples=subsindex(obj,s)
            error('This function is changed. Make sure it is working properly, then move.')
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

