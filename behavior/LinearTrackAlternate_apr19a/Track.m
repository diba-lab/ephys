classdef Track<Singleton
    %SLEEPDEPRIVATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FileName
        PokeRecord
    end
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function obj = Track()
            % Initialise your custom properties.
            obj.FileName='AH_train03.csv';
            if ~isfile(obj.FileName)
                pr = cell2table(cell(0,3), 'VariableNames', {'Time', 'Type','Pin'});
                a.Time = datetime(now,'ConvertFrom','datenum');
                a.Time.Format=obj.getDateTimeFormat;
                a.Type=0;
                a.Pin='pin';
                pr=[pr; struct2table(a)];
                obj.PokeRecord=pr;
                writetable(obj.PokeRecord,obj.FileName,'Delimiter',',','QuoteStrings',false);
            end
        end
    end
    
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = Track();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        
        function obj = getFile(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.PokeRecord=readtable(obj.FileName,'Format',strcat('%{',obj.getDateTimeFormat,'}D%f%s'));
        end
        function f = getDateTimeFormat(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            f= 'MM/dd/uuuu HH:mm:ss.SSS';
        end
        function obj = add(obj,type,event)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj=obj.getFile;
            Time = datetime(now,'ConvertFrom','datenum');
            Time.Format=obj.getDateTimeFormat;
            Type=type;
            theArduino=ArduinoWrapper.instance.getArduino;
            theArduino.writeDigitalPin('D4', 1);
            pause(.100);
            theArduino.writeDigitalPin('D4',0);
            if isa(event,'TouchedEventData')
                Pin=event.getSensorPin;
            else
                Pin=event.getMotorPin;
            end
            cellEvent={Time,Type,Pin};
            obj.PokeRecord=[obj.PokeRecord ; cellEvent];
            obj.save;
            obj.print;
            obj.plot;
        end
        function [] = save(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            filename=obj.FileName;
            writetable(obj.PokeRecord,filename,'Delimiter',',','QuoteStrings',false);
        end
        function [] = print(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj=obj.getFile;
            display(obj.PokeRecord);
        end
        function [] = plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj=obj.getFile;
            time1=obj.PokeRecord.Time;
            time2=hours(time1-time1(1));
            type1=  obj.PokeRecord.Type;
            figure(123321);
            binlims=[0 2.5];
            binwidth=1/12;
            for itype=1:2
                h=histogram(time2(type1==itype));
                hold on;
                h.BinLimits=binlims+(itype-1)*binwidth*.2;
                h.BinWidth=binwidth;
                h.FaceAlpha=.7;
                hs(itype)=h;
            end
            ax=gca;
            l=legend({'Sensed','Watered'});
            l.Location='best';
            hold off
        end
    end
end

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        