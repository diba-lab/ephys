classdef Channel < neuro.basic.Oscillation & matlab.mixin.CustomDisplay
    %CHANNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        TimeIntervalCombined
    end
    properties
        ChannelName
        Info
    end
    
    methods
        function obj = Channel(channelname, voltageArray, timeIntervalCombined)
            %CHANNEL Construct an instance of this class
            %   Detailed explanation goes here
            if size(voltageArray,1)>1
                voltageArray=voltageArray';
            end
            if numel(voltageArray)>timeIntervalCombined.getNumberOfPoints
                voltageArray=voltageArray(1:timeIntervalCombined.getNumberOfPoints);
            elseif numel(voltageArray)<timeIntervalCombined.getNumberOfPoints
                diff1=timeIntervalCombined.getNumberOfPoints-numel(voltageArray);
                voltageArray=[voltageArray zeros(1,diff1)];
            end
            obj@neuro.basic.Oscillation(voltageArray,...
                timeIntervalCombined.getSampleRate);
            try
                obj.ChannelName=channelname;
            catch
            end
            try
                obj.TimeIntervalCombined=timeIntervalCombined;
            catch
            end
        end
        function print(obj)
            fprintf(...
                'Channel %s, lenght %d, %s -- %s, %dHz\n',...
                num2str(obj.ChannelName),numel(obj.getValues),...
                datestr(obj.TimeIntervalCombined.getStartTime),...
                datestr(obj.TimeIntervalCombined.getEndTime),...
                obj.SampleRate);
        end
        function st=getStartTime(obj)
            ti=obj.getTimeInterval;
            st=ti.getStartTime;
        end
        function en=getEndTime(obj)
            ti=obj.getTimeInterval;
            en=ti.getEndTime;
        end
        function len=getLength(obj)
            ti=obj.getTimeInterval;
            len=seconds(ti.getNumberOfPoints/ti.getSampleRate);
        end
        function chan=getChannelName(obj)
            chan=obj.ChannelName;
        end
        function info=getInfo(obj)
            info=obj.Info;
        end
        function obj=setChannelName(obj,name)
            obj.ChannelName=name;
        end
        function obj=setInfo(obj,info)
            obj.Info=info;
        end
        function st=getTimeIntervalCombined(obj)
            st=obj.TimeIntervalCombined;
        end
        function st=getTimeInterval(obj)
            st=obj.TimeIntervalCombined;
        end
        function ch=setTimeInterval(obj,ti)
            ch=neuro.basic.Channel(obj.ChannelName,obj.Values,ti);
            ch=ch.setInfo(obj.Info);
        end
        function ets=getEphysTimeSeries(obj)
            ets=neuro.basic.EphysTimeSeries(obj.getValues,obj.getSampleRate,obj.getChannelName);
            ets=ets.setInfo(obj.Info);
        end
        function obj=getTimeWindowForAbsoluteTime(obj,window)
            error('Obsolete. Use getTimeWindow instead.')
        end
        function obj=getTimeWindow(obj,windows)
            ticd=obj.TimeIntervalCombined;
            basetime=ticd.getDate;
            for iwind=1:size(windows,1)
                window=windows(iwind,:);
                if isstring(window)
                    window1=datetime(window,'Format','HH:mm');
                    add1(1)=hours(window1(1).Hour)+minutes(window1(1).Minute);
                    add1(2)=hours(window1(2).Hour)+minutes(window1(2).Minute);
                    time(iwind,1)=basetime+add1(1);
                    time(iwind,2)=basetime+add1(2);
                elseif isduration(window)
                    add1=window;
                    time(iwind,1)=basetime+add1(1);
                    time(iwind,2)=basetime+add1(2);
                elseif isdatetime(window)
                    time(iwind,1)=window(1);
                    time(iwind,2)=window(2);
                end
            end
            for iwind=1:size(time,1)
                int=time(iwind,:);
                sample(iwind,:)=ticd.getSampleForClosest(int);
            end
            samples=[];
            for iwind=1:size(sample,1)
                thesamples=sample(iwind,1):sample(iwind,2);
                samples=horzcat(samples,thesamples);
            end        
            obj.Values=obj.Values(samples);
            ticd1=ticd.getTimeIntervalForTimes(time);
            obj.TimeIntervalCombined=ticd1;
        end
        
        function p=plot(obj,varargin)
            va=obj.getValues;
            t=obj.TimeIntervalCombined;
            if isa(t,'TimeIntervalCombined')
                hold on
                tis=t.timeIntervalList;
                index_va=1;
                for iti=1:tis.length
                    ati=tis.get(iti);
                    t_s=ati.getTimePointsInSec;
                    ava=va(index_va:(index_va+ati.getNumberOfPoints-1));
                    index_va=index_va+ati.getNumberOfPoints;
                    t_s=ati.getStartTime+seconds(t_s);
                    p(iti)=plot(t_s,ava(1:numel(t_s)),varargin{:});
                end
            else
                t_s=t.getTimePointsInSec;
                t_s=t.getStartTime+seconds(t_s);
                diff1=numel(t_s)-numel(va);
                va((numel(va)+1):(numel(va)+diff1))=zeros(diff1,1);
                p=plot(t_s,va(1:numel(t_s)),varargin{:});
            end
        end
        function obj=plus(obj,aChan)
            obj.TimeIntervalCombined=obj.TimeIntervalCombined+aChan.getTimeInterval;
            obj.voltageArray=[obj.getVoltageArray ;aChan.voltageArray];
        end
        function ets=getTimeSeries(obj)
            ets=neuro.basic.EphysTimeSeries(obj.getValues,obj.getSampleRate,obj.ChannelName);
        end
        function thpk=getFrequencyBandPeak(obj,freq)
            tfm=obj.getWhitened.getTimeFrequencyMap(...
                neuro.tf.TimeFrequencyWavelet(logspace(log10(freq(1)),log10(freq(2)),diff(freq)*5)));
            [thpkcf1,thpkpw1]=tfm.getFrequencyBandPeak(freq);
            thpkcf=neuro.basic.Channel('CF',thpkcf1.getValues,obj.TimeIntervalCombined);
            thpkcf=thpkcf.setInfo(obj.Info);
            thpkpw=neuro.basic.Channel('Power',thpkpw1.getValues,obj.TimeIntervalCombined);
            thpkpw=thpkpw.setInfo(obj.Info);
            thpk=experiment.plot.thetaPeak.ThetaPeak(thpkcf,thpkpw);
            thpk=thpk.addSignal(obj);
        end
        
    end
    methods (Access = protected)
        function header = getHeader(obj)
            if ~isscalar(obj)
                header = getHeader@matlab.mixin.CustomDisplay(obj);
            else
                headerStr = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                headerStr = [headerStr,' with Customized Display'];
                header = sprintf('%s\n',headerStr);
            end
        end
    end
end

