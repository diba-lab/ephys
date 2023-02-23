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
                if isstring(ch)||iscellstr(ch)||isinteger(ch)
                    obj.channels=ch;
                else
                    l.error('Provide string or scalar.')
                end
                if isa(time,'neuro.time.TimeIntervalCombined')||isa(time,'neuro.time.TimeInterval')
                    obj.time = time;
                else
                    l.error('Provide neuro.time.TimeIntervalCombined object.')
                end
                if isequal(size(data),[numel(ch.getActiveChannels) time.getNumberOfPoints])
                    obj.data=data;
                else
                    l.error('Data size is not compatible with channel and time info.')
                end
            end
        end
        
        function obj = getLowpassFiltered(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mat1=table2array(obj.data)';
            nanidx=any(isnan(mat1));
            dat=ft_preproc_lowpassfilter(mat1(:,~nanidx), ...
                obj.time.getSampleRate,freq);
            mat1(:,~nanidx)=dat;
            obj.data=array2table(mat1',VariableNames= ...
                obj.data.Properties.VariableNames);
        end
        function obj = getMedianFiltered(obj,winSeconds)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.data=smoothdata(obj.data,"movmedian", ...
                winSeconds*obj.time.getSampleRate);
        end
        function t1 = getDataTable(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t=array2table(obj.time.getTimePointsZT',...
                VariableNames={'TimeZT'});
            t1=[obj.data t];
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

