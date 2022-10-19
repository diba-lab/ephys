classdef TimeIntervalZT < neuro.time.TimeInterval
    %TIMEINTERVALZT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ZeitgeberTime
    end
    
    methods
        function obj = TimeIntervalZT(varargin)
            %TIMEINTERVALZT Construct an instance of this class
            %   Detailed explanation goes here
            if isa(varargin{1},'neuro.time.TimeInterval')
                ti=varargin{1};
                startTime=ti.StartTime;
                sampleRate=ti.SampleRate;
                numberOfPoints=ti.NumberOfPoints;
                zt=varargin{2};
            else
                startTime=varargin{1};
                sampleRate=varargin{2};
                numberOfPoints=varargin{3};
                zt=varargin{4};
            end
            obj@neuro.time.TimeInterval(startTime, sampleRate, numberOfPoints)
            if isduration(zt)
                obj.ZeitgeberTime= zt+obj.getDate;
            elseif isdatetime(zt)
                obj.ZeitgeberTime= zt;
            end
        end
        function S=getStruct(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            S=getStruct@neuro.time.TimeInterval(obj);
            S.ZeitgeberTime=obj.ZeitgeberTime;
        end        
        function str=tostring(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            str1=tostring@neuro.time.TimeInterval(obj);
            str2=datestr(obj.ZeitgeberTime,'HH AM');
            str=sprintf('\tZT:%s %s',str2,str1);
        end

        function zt=getZeitgeberTime(obj)
            if isduration(obj.ZeitgeberTime)
                zt=obj.ZeitgeberTime+obj.getDate;
            elseif isdatetime(obj.ZeitgeberTime)
                zt=obj.ZeitgeberTime;
            end
        end
        function tps=getTimePointsInSecZT(obj)
            tps=0:(1/obj.SampleRate):((obj.NumberOfPoints-1)/obj.SampleRate);
            diff1=seconds(obj.getStartTime-obj.getDatetime(obj.getZeitgeberTime));
            tps=tps+diff1;
        end
    end
end

