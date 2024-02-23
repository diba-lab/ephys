classdef EventFile
    %EVENTFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimeWindowsDuration
        Location
    end
    
    methods
        function obj = EventFile(file)
            %EVENTFILE Construct an instance of this class
            %   Detailed explanation goes here
            if exist('file','var')
                if isfile(file)
                    t=readtable(file,'FileType','text');
                    evtnames=unique(t.Var2);
                    times=seconds(t.Var1/1000);
                    for ievt=1:numel(evtnames)
                        evt=evtnames{ievt};
                        all1(:,ievt)=times(ismember(t.Var2,evt));
                    end
                    obj.TimeWindowsDuration=time.TimeWindowsDuration( ...
                        array2table(all1,VariableNames=evtnames));
                    obj.Location=file;
                else
                    l=logging.Logger.getLogger;
                    l.error('Incorrect file.');
                end
            else
                l=logging.Logger.getLogger;
                l.error('Provide a file.')
            end
        end
        
        function fname=saveTable(obj,location)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if exist('location','var')
                fname=location;
            else
                [fol,name,~]=fileparts(obj.Location);
                fname=fullfile(fol,[name '.csv']);
            end
            tt=array2table(seconds(table2array(obj.TimeWindowsDuration.getTimeTable)), ...
                "VariableNames",obj.TimeWindowsDuration.TimeTable.Properties.VariableNames);
            writetable(tt,fname);
        end
    end
end

