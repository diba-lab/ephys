classdef StateRatios
    %STATERATIOS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        State
    end
    
    methods
        function obj = StateRatios(state)
            %STATERATIOS Construct an instance of this class
            %   Detailed explanation goes here
            ist=1;
            for istate=1:numel(state)
                st1=state(istate);
                if ismember(st1.state,[1 2 3 5])
                    newst(ist)=st1;ist=ist+1;
                end
            end
            obj.State=newst;
        end
        
        function list = getStateList(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            state=obj.State;
            list=unique([state.state]);
        end
    end
end

