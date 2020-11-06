classdef (Abstract) Oscillation
    %OSCILLATION Summary of this class goes here
    %   Detailed explanation goes here
    properties (Access=protected)
        voltageArray
        sampleRate
    end
    methods
        function obj = Oscillation(voltageArray, sampleRate)
            %OSCILLATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.sampleRate=sampleRate;
            if ~isa(voltageArray,'double')
                obj.voltageArray=double(voltageArray);
            else
                obj.voltageArray=voltageArray;
            end
        end
        function timeFrequencyMap = getTimeFrequencyMap(obj,...
                timeFrequencyMethod)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            try
                [ticd1, res]=obj.getTimeIntervalCombined.getDownsampled(...
                obj.getTimeIntervalCombined.getSampleRate/...
                timeFrequencyMethod.movingWindow(2));
            obj.voltageArray(res)=[];
            catch
                ticd1=obj.getTimeIntervalCombined;
            end
            timeFrequencyMap=timeFrequencyMethod.execute(...
                obj.voltageArray, obj.getSampleRate);
            timeFrequencyMap=timeFrequencyMap.setTimeintervalCombined(ticd1);
        end
        function p1=plot(obj,varargin)
            p1=plot(obj.time,obj.voltageArray,varargin{:});
            ax=gca;
            ax.XLim=[obj.time(1) obj.time(end)];
        end

        function obj=getDownSampled(obj,newRate)
            rate=obj.sampleRate/newRate;
            obj.voltageArray=downsample(obj.getVoltageArray,rate);
            obj.sampleRate=newRate;
        end
        function ps=getPSpectrum(obj)
            [pxx,f] = pspectrum(double(obj.voltageArray),obj.getSampleRate,...
                'FrequencyLimits',[1 250]);
            ps=PowerSpectrum(pxx,f);
        end
        function ps=getPSpectrumChronux(obj)
%             params.tapers=[3 5];
            params.Fs=obj.getSampleRate;
            params.fpass=[1 250];
            [S,f] = mtspectrumc( obj.voltageArray, params );
            ps=PowerSpectrum(S,f);
        end
        function specslope=getPSpectrumSlope(obj)
            LFP.data=obj.voltageArray;
            LFP.timestamps=obj.get;
            LFP.samplingRate=obj.getSampleRate;
            [specslope,~] = bz_PowerSpectrumSlope(LFP,3,1,...
                'frange',[4 250],'nfreqs',250,'showfig',false);
        end
        function obj=getWhitened_Obsolete(obj, fraquencyRange)
            Fs=obj.samplingRate;
            x=obj.voltageArray;
            x_detrended=detrend(x);
            if nargin>1
                x_whitened = whitening(x_detrended', Fs, 'freq', fraquencyRange);
            else
                x_whitened = whitening(x_detrended', Fs);
            end
            obj.voltageArray=x_whitened';
        end
        function obj=getWhitened(obj)
            obj.voltageArray = reshape(WhitenSignal(obj.voltageArray,[],1),size(obj.voltageArray));
        end
        function obj=getLowpassFiltered(obj,filterFreq)
            obj.voltageArray=ft_preproc_lowpassfilter(...
                obj.voltageArray',obj.sampleRate,filterFreq);
        end
        function obj=getHighpassFiltered(obj,filterFreqBand)
            obj.voltageArray=ft_preproc_highpassfilter(...
                obj.voltageArray',obj.sampleRate,filterFreqBand,[],[],[]);
        end
        function obj=getBandpassFiltered(obj,filterFreqBand)
            obj.voltageArray=ft_preproc_bandpassfilter(...
                obj.voltageArray',obj.sampleRate,filterFreqBand,[],[],[]);
        end
        function time=getVoltageArray(obj)
            time = obj.voltageArray;
        end
        function time=getSampleRate(obj)
            time = obj.sampleRate;
        end
        function obj=getIdxPoints(obj,idx)
            va = obj.voltageArray;
            obj.voltageArray=va(idx);
        end
        function obj=setSampleRate(obj,newrate)
            obj.sampleRate=newrate;
        end
    end
end

