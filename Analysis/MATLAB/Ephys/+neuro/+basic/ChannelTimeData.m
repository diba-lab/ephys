classdef ChannelTimeData
    %CHANNELTIMEDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channels
        time
        data
    end
    
    methods
        function obj = ChannelTimeData(ch, time, data)
            %CHANNELTIMEDATA Construct an instance of this class
            %   Detailed explanation goes here
            l= logging.Logger.getLogger;
            if nargin==3
                if isstring(ch)||iscellstr(ch)||isnumeric(ch)
                    obj.channels=ch;
                else
                    l.error('Provide string or scalar.')
                end
                if isa(time,'neuro.time.TimeIntervalCombined')||isa(time,'neuro.time.TimeInterval')
                    obj.time = time;
                else
                    l.error('Provide neuro.time.TimeIntervalCombined object.')
                end
                if isequal(size(data),[numel(ch) time.getNumberOfPoints])
                    obj.data=data;
                else
                    l.error('Data size is not compatible with channel and time info.')
                end
            end
        end
        
        function str = toString(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            str=sprintf('%d Channels: %s, %s',size(obj.data,2), ...
                strjoin(obj.channels),obj.time.tostring);
        end
        function obj = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.data=-obj.data/max(max(obj.data))/2;
            for ic=1:size(obj.data)
                obj.data(ic,:)=obj.data(ic,:)+ic;
            end
            time1=seconds(obj.time.getTimePointsZT);
            plot(time1,obj.data,Color='k');
        end
        function obj = getLowpassFiltered(obj, freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if istable(obj.data)
                data1=table2array(obj.data)';
            else
                data1=obj.data;
            end
            nansidx=any(isnan(data1));
            data3=nan(size(data1));
            data1(:,nansidx)=[];
            data2=ft_preproc_lowpassfilter(data1, ...
                obj.time.getSampleRate, freq);
            data3(:,~nansidx)=data2;
            if istable(obj.data)
                obj.data=array2table(data3','VariableNames',obj.data.Properties.VariableNames);
            else
                obj.data=data3;
            end
                        
        end
        function obj = getHighpassFiltered(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            obj.data=ft_preproc_highpassfilter(obj.data, ...
                obj.time.getSampleRate,freq);
            
        end
        function obj = getMedianFiltered(obj,winSeconds)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.data=smoothdata(obj.data,"movmedian", ...
                winSeconds*obj.time.getSampleRate);
        end
        function obj = getDetrended(obj,winSeconds)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.data=detrend(obj.data);
        end
        function t1 = getDataTable(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t=array2table(obj.time.getTimePointsZT',...
                VariableNames={'TimeZT'});
            t1=[obj.data t];
        end
        function csd = getCSD(obj)
            obj.data=double(obj.data);
            doDetrend=false;
            temp_sm=seconds(.01);
            spat_sm=0;
            objorg=obj;
            % detrend
            if doDetrend
                obj=obj.getDetrended;
            end

            % temporal smoothing
            if temp_sm > 0
                for ch = 1:size(obj.data,1)
                    obj.data(:,ch) = smooth(obj.data(:,ch),...
                        round(seconds(temp_sm)*obj.time.getSampleRate),'sgolay');
                end
            end

            % spatial smoothing
            if spat_sm > 0
                for t = 1:size(obj.data,2)
                    obj.data(t,:) = smooth(obj.data(t,:),spat_sm,'lowess');
                end
            end

            % calculate CSD
            CSD = diff(obj.data,2,1);

            csd=neuro.csd.CurrentSourceDensity(CSD,objorg);
        end
        function obj = insertNansForGaps(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isa(obj.time,'neuro.time.TimeIntervalCombined')
                obj.time.getNumberOfPoints
                til=obj.time.getTimeIntervalList.createIterator;
                it=1;
                sampleNo=1;
                while til.hasNext
                    timeInterval=til.next;
                    endt(it)=timeInterval.getEndTime;
                    if it>1 % write nans if not the first timeInterval
                        numnans=round(seconds(timeInterval.getStartTime-endt(it-1))*timeInterval.getSampleRate);
                        newdata(end+1:end+numnans,:)= ...
                            array2table(nan(numnans,size(obj.data,2)), ...
                            VariableNames=obj.data.Properties.VariableNames);
                    else
                        timeIntervalFinal=timeInterval;
                        newdata=[];
                    end
                    newdata=[newdata; obj.data(sampleNo:timeInterval.getNumberOfPoints,:)];
                    it=it+1;
                end
                obj.data=newdata;
                timeIntervalFinal.NumberOfPoints=height(obj.data);
                obj.time=timeIntervalFinal;
            else
                warning(['No gaps to be filled by nans. Object is ''%s'', not a ''' ...
                    'neuro.time.TimeIntervalCombined''.\n'],class(obj.time));

            end
        end
    end
end

