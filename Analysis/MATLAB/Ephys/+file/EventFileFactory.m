classdef EventFileFactory
    %EVENTFILEFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
    end
    methods (Static)
        function events = getEvents(filename)
            T=  readtable(filename,'FileType','text',...
                'Delimiter','tab','ReadVariableNames',false);
            try
            times=T.Var1;
            tags=T.Var2;
            for ievent=1:size(T,1)
                events(ievent)=tsdata.event(tags{ievent},times(ievent)/1000);
            end
            catch
                warning(sprintf('There is a problem in file:\n%s\n',filename));
            end
        end
        
    end
end

