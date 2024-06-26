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
            obj.FileName='train2022-03-22.csv';
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
            obj.PokeRecord=readtable(obj.FileName,'Format',strcat('%{',obj.getDateTimeFormat,'}D%d%s'));
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

            if isa(event,'TouchedEventData')
                Pin=event.getSensorPin;
            else
                Pin=event.getMotorPin;
            end
            cellEvent={Time,Type,Pin};
            obj.PokeRecord=[obj.PokeRecord ; cellEvent];
            obj.save;
            if ~isa(event,'TouchedEventData')
                obj.print;
                obj.plot;
            end
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
            pins=obj.PokeRecord.Pin;
            pinsua=unique(pins,'stable');
            typea=  obj.PokeRecord.Type;
            try close(123321); catch, end
                f=figure(123321);
            f.Position(3)=f.Position(3)*2;
            colors=colororder;
            markerType={'o','d'};
            actionType={'Sensed','Watered'};
            il=1;
            for itype=1:2
                idx=typea==itype;
                pinsu=unique(pins(idx));
                for ipin=1:numel(pinsu)
                    idx2=ismember(pins,pinsu{ipin});
                    idxf=idx&idx2;
                    type1=ones(1,sum(idxf));
                    if itype==1
                        type1=type1+rand(1,numel(type1))*.3;
                    end
                    h(il)=scatter(obj.PokeRecord.Time(idxf),type1,'filled',markerType{itype});
                    h(il).MarkerFaceColor=colors(ismember(pinsua,pinsu{ipin}),:);
                    h(il).MarkerFaceAlpha=.7;
                    if itype==2
                        h(il).SizeData=h(il).SizeData*2;
                    end
                    pinstr{il}=char(strcat(actionType(itype), ' (pin-',pinsu{ipin},')'));il=il+1;
                    hold on;
                end
            end
            try
                l=legend(h,pinstr);
                l.Location='best';
            catch
            end
            ax=gca;
            ax.YTick=[];
            ax.YLabel.String='Water Well Events';
            ax.XLabel.String='Time';
            ax.YLim=[.9 1.4];
            ax.Color='none';
            hold off;
        end
    end
end

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        