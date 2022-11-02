classdef TimeSeries
    %TIMESERIES Summary of this class goes here
    %   Detailed explanation goes here
    properties (Access=public)
        Values
        SampleRate
    end
    methods
        function obj = TimeSeries(values, sampleRate)
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
        function obj=getDownSampled(obj,newRate)
            ratio=obj.SampleRate/newRate;
            obj.Values=downsample(obj.getValues,ratio);
            obj.SampleRate=newRate;
        end
        function obj=getReSampled(obj,newRate)
            obj.Values=resample(obj.getValues, newRate,obj.getSampleRate);
            obj.SampleRate=newRate;
        end
        function obj=getFillMissing(obj,window)
            obj.Values=fillmissing(obj.getValues,"movmedian",window*obj.SampleRate);
        end
        function l=getLength(obj)
            l=seconds(obj.getNumberOfPoints/obj.getSampleRate);
        end
        function np=getNumberOfPoints(osc)
            np=numel(osc.Values);
        end
        function ts=getTimeStamps(osc)
            ts=linspace(0, osc.getNumberOfPoints/osc.getSampleRate, osc.getNumberOfPoints);
        end
        function obj=getMedianFiltered(obj,windowInSeconds,varargin)
            obj.Values=medfilt1(obj.Values,...
                obj.getSampleRate*windowInSeconds,varargin{:});
        end
        function obj=getMeanFiltered(obj,windowInSeconds)
            obj.Values=smoothdata(obj.Values,...
                'movmean', obj.getSampleRate*windowInSeconds);
        end
        function obj=getGaussianFiltered(obj,windowInSeconds)
            obj.Values=smoothdata(obj.Values,...
                'gaussian', obj.getSampleRate*windowInSeconds);
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
        function p1=plot(obj,varargin)
            ts=obj.getTimeStamps;
            vals=obj.getValues;
            p1=plot(ts,vals,varargin{:});
            %             ax=gca;
            %             ax.XLim=[ts(1) ts(end)];
        end
    end
end

