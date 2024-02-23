classdef Channel < neuro.basic.Oscillation & matlab.mixin.CustomDisplay
    %CHANNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        TimeIntervalCombined
    end
    properties
        ChannelName
        Info
    end

    methods
        function obj = Channel(channelname, voltageArray,...
                timeIntervalCombined)
            %CHANNEL Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                if size(voltageArray,1)>1
                    voltageArray=voltageArray';
                end
                numdiff= numel(voltageArray)-...
                    timeIntervalCombined.getNumberOfPoints;
                if numdiff<3 && numdiff>0
                    timeIntervalCombined=...
                        timeIntervalCombined.addTimePoints(numdiff);
                end
                obj.SampleRate=timeIntervalCombined.getSampleRate;
                obj.Values=voltageArray;
                try
                    obj.ChannelName=channelname;
                catch
                end
                try
                    obj.TimeIntervalCombined=timeIntervalCombined;
                catch
                end
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
        function episodes=lt(obj,num)
            if isnumeric(num)&&numel(num)==1
                idx=obj.getValues<num;
                % Find the indices where binary episodes start
                zt=obj.TimeIntervalCombined.getTimePointsZT';
                episodeStart1 = diff([median(idx), idx]) == -1;
                episodeStart=hours(hours(zt(episodeStart1)));
                % Find the indices where binary episodes end
                episodeEnd1 = diff([idx, median(idx)]) == 1;
                episodeEnd=hours(hours(zt(episodeEnd1)));
                episodes=array2table([episodeStart episodeEnd], ...
                    VariableNames={'Start','Stop'});
            end
        end
        function episodes=gt(obj,num)
            if isnumeric(num)&&numel(num)==1
                idx=obj.getValues>num;
                % Find the indices where binary episodes start
                zt=obj.TimeIntervalCombined.getTimePointsZT';
                episodeStart1 = diff([median(idx), idx]) == 1;
                episodeStart=hours(hours(zt(episodeStart1)));
                % Find the indices where binary episodes end
                episodeEnd1 = diff([idx, median(idx)]) == -1;
                episodeEnd=hours(hours(zt(episodeEnd1)));
                episodes=array2table([episodeStart episodeEnd], ...
                    VariableNames={'Start','Stop'});
            end
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
        function obj=getDownSampled(obj,newRate)
            ratio=obj.SampleRate/newRate;
            obj=getDownSampled@neuro.basic.Oscillation(obj,newRate);
            obj=obj.setTimeInterval(obj.getTimeInterval.getDownsampled(ratio));
        end
        function obj=getReSampled(obj,newRate)
            ratio=obj.SampleRate/newRate;
            obj=getReSampled@neuro.basic.Oscillation(obj,newRate); 
            obj=obj.setTimeInterval(obj.getTimeInterval.getDownsampled(ratio));
        end

        function obj=setTimeInterval(obj,ti)
            obj.TimeIntervalCombined=ti;
        end
        function ets=getEphysTimeSeries(obj)
            ets=neuro.basic.EphysTimeSeries(obj.getValues, ...
                obj.getSampleRate,obj.getChannelName);
            ets=ets.setInfo(obj.Info);
        end
        function obj4=getHilbertPhase(obj1)
            obj2=getHilbertPhase@neuro.basic.Oscillation(obj1);
            obj3=neuro.basic.ChannelProcessed(obj2);
            obj3.parent=obj1;
            obj4=neuro.basic.ChannelPhase(obj3);
            obj4.processingInfo=[];
            obj4.processingInfo.hilbertTransformedPhase=true;
        end
        function obj4=getHilbertPhaseKamran(obj1)
            obj2=getHilbertPhaseKamran@neuro.basic.Oscillation(obj1);
            obj3=neuro.basic.ChannelProcessed(obj2);
            obj3.parent=obj1;
            obj4=neuro.basic.ChannelPhase(obj3);
            obj4.processingInfo=[];
            obj4.processingInfo.hilbertTransformedPhase=true;
        end
        function obj=getTimeWindowForAbsoluteTime(obj,window)
            error('Obsolete. Use getTimeWindow instead.')
        end
        function obj=getTimeWindow(obj,window)
            ticd=obj.TimeIntervalCombined;
            basetime=ticd.getDate;

            if isstring(window)
                window1=datetime(window,'Format','HH:mm');
                add1(1)=hours(window1(1).Hour)+minutes(window1(1).Minute);
                add1(2)=hours(window1(2).Hour)+minutes(window1(2).Minute);
                time1=basetime+add1;
            elseif isduration(window)
                add1=window;
                time1=basetime+add1;
            elseif isdatetime(window)
                time1=window;
            elseif isa(window,'time.ZT')||isa(window,'time.ZeitgeberTime')
                time1=ticd.getZeitgeberTime+window.Duration;
            end
            samplewlist=ticd.getSampleForClosest(time1);
            ticds=cell(size(samplewlist,1),0);
            for is=1:size(samplewlist,1)
                samplew=samplewlist(is,:);
                ticds{is}=ticd.getTimeIntervalForSamples(samplew);
            end
            ticdall=time.TimeIntervalCombined+ticds;

            % Get the start and stop indices as arrays
            startIndices = samplewlist(:,1);
            stopIndices = samplewlist(:,2);

            % Calculate the number of elements in each range
            rangeSizes = stopIndices - startIndices + 1;

            % Create an array of full indices
            fullIndices = arrayfun(@(start, size) (start:(start+size-1)), ...
                startIndices, rangeSizes, 'UniformOutput', false);

            % Concatenate the arrays of full indices into a single array
            sampleall = [fullIndices{:}];

            obj.Values=obj.Values(sampleall);
            obj.TimeIntervalCombined=ticdall;
        end
        
        function p=plot(obj,varargin)
            va=obj.getValues;
            t=obj.TimeIntervalCombined;
            abs1=ismember(varargin,{'Absolute','Abs','absolute','abs'} );
            varargin(abs1)=[];
            zt1=ismember(varargin,{'ZT','zt'});
            varargin(zt1)=[];
            s1=ismember(varargin,{'s','sec','second','seconds', ...
                'S','Sec','Second','Seconds'});
            varargin(s1)=[];
            h1=ismember(varargin,{'h','hours','H','Hours'});
            varargin(h1)=[];

            if isa(t,'time.TimeIntervalCombined')
                tis=t.timeIntervalList;
                index_va=1;
                for iti=1:tis.length
                    ati=tis.get(iti);
                    if any(abs1)
                        timepoints=ati.getTimePointsInAbsoluteTimes;
                    else
                        tp=ati.getTimePointsZT;
                        if ~any(s1)
                            timepoints=hours(tp);
                        else
                            timepoints=seconds(tp);
                        end
                    end
                    ava=va(:,index_va:(index_va+ati.getNumberOfPoints-1));
                    p(iti,:)=plot(timepoints,ava);
                    p(iti).LineWidth=1.5;
                    p(iti).Marker='none';
                    p(iti).LineStyle="-";
                    if iti>1
                        p(iti).Color=p(iti-1).Color;
                    end
                    hold on
                end
                hold off
            else
                if any(abs1)
                    timepoints=t.getTimePointsInAbsoluteTimes;
                    varargin(ismem)
                else
                    tp=t.getTimePointsZT;
                    if ~any(s1)
                        timepoints=hours(tp);
                    else
                        timepoints=seconds(tp);
                    end
                end
                diff1=numel(timepoints)-numel(va);
                va((numel(va)+1):(numel(va)+diff1))=zeros(diff1,1);
                p=plot(timepoints,va(1:numel(timepoints)),varargin{:});
            end
            if ~any(abs1)
                if ~any(s1)
                    xlabel('ZT (h)')
                else
                    xlabel('ZT (s)')
                end
            else
                xlabel('Time')
            end
        end
        function obj=plus(obj,val)
            if isa(val,'neuro.basic.Channel')
                obj.TimeIntervalCombined=obj.TimeIntervalCombined+...
                    val.getTimeInterval;
                obj.Values=[obj.Values val.Values];
                
            elseif isnumeric(val)
                obj.Values=obj.Values+val;
            end
        end
        function ets=getTimeSeries(obj)
            ets=neuro.basic.EphysTimeSeries(obj.getValues, ...
                obj.getSampleRate,obj.ChannelName);
        end
        function [thpk, tfm]=getFrequencyBandPeakWavelet(obj,freq)
            tfm=obj.getWhitened.getTimeFrequencyMap(...
                neuro.tf.TimeFrequencyWavelet( ...
                logspace(log10(freq(1)),log10(freq(2)),diff(freq)*5) ...
                ));
            [thpkcf1,thpkpw1]=tfm.getFrequencyBandPeak(freq);
            thpkcf=neuro.basic.Channel('CF',thpkcf1.getValues, ...
                obj.TimeIntervalCombined);
            thpkcf=thpkcf.setInfo(obj.Info);
            thpkpw=neuro.basic.Channel('Power',thpkpw1.getValues, ...
                obj.TimeIntervalCombined);
            thpkpw=thpkpw.setInfo(obj.Info);
            thpk=experiment.plot.thetaPeak.ThetaPeak(thpkcf,thpkpw);
            thpk=thpk.addSignal(obj);
        end
        function thpk=getFrequencyBandPeakMT(obj,freq)
            tfm=obj.getWhitened.getTimeFrequencyMap(...
                neuro.tf.TimeFrequencyChronuxMtspecgramc(...
                freq,[2 1]));
            [thpkcf1,thpkpw1]=tfm.getFrequencyBandPeak(freq);
            thpkcf=neuro.basic.Channel('CF',thpkcf1.getValues, ...
                obj.TimeIntervalCombined);
            thpkcf=thpkcf.setInfo(obj.Info);
            thpkpw=neuro.basic.Channel('Power',thpkpw1.getValues, ...
                obj.TimeIntervalCombined);
            thpkpw=thpkpw.setInfo(obj.Info);
            thpk=experiment.plot.thetaPeak.ThetaPeak(thpkcf,thpkpw);
            thpk=thpk.addSignal(obj);
        end
        function str=toString(obj)
        str=sprintf('ch%s-n%dHz-%d-%s-%s', string(obj.ChannelName),...
            obj.SampleRate, ...
            obj.getNumberOfPoints, ...
            string([obj.TimeIntervalCombined.getStartTime, ...
            obj.TimeIntervalCombined.getEndTime]));
        end
        
    end
    methods (Access = protected)
        function header = getHeader(obj)
            if ~isscalar(obj)
                header = getHeader@matlab.mixin.CustomDisplay(obj);
            else
                headerStr = ...
                    matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                headerStr = [headerStr,' with Customized Display'];
                header = sprintf('%s\n',headerStr);
            end
        end
    end
end

