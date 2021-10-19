classdef EventFile
    %EVENTFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimeWindowsDuration
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
                    obj.TimeWindowsDuration=neuro.time.TimeWindowsDuration( ...
                        array2table(all1,VariableNames=evtnames));
                else
                    l=logging.Logger.getLogger;
                    l.error('Incorrect file.');
                end
            else
                l=logging.Logger.getLogger;
                l.error('Provide a file.')
            end
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

