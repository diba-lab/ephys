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
            obj.State=state;
        end
        
        function [] = plotAwakeFractionPreceeding(obj)
            a=obj.getStateFractionPreceeding( ...
                categorical({'A-WAKE','Q-WAKE'}),categorical({'SWS','REM'}));
            imagesc([min(a.time) max(a.time)],[],a.awakeFraction');
        end
        function res = getStateFractionPreceeding(obj,interest,rest)
            res.ZTtime=obj.State.ZTEnd;
            for iint=1:numel(interest)
                var=string(interest(iint));
                if iint==1
                    suminterest=obj.State.(var);
                else
                    suminterest=suminterest+obj.State.(var);
                end
            end            
            for iint=1:numel(rest)
                var=string(rest(iint));
                if iint==1
                    sumrest=obj.State.(var);
                else
                    sumrest=sumrest+obj.State.(var);
                end
            end

            res.interest=suminterest;
            res.rest=sumrest;
            res.sum=res.interest+res.rest;
            res.fraction=res.interest./res.sum;
        end
        function res = getAwakeFractionPreceeding(obj)
            res=obj.getStateFractionPreceeding( ...
                categorical({'A-WAKE','Q-WAKE'}), ...
                categorical({'SWS','REM'}));
            res.awakedur=res.interest;
            res.sleepdur=res.rest;
            res.sum=res.awakedur+res.sleepdur;
            res.awakeFraction=res.awakedur./res.sum;
        end
        function res = getSleepFractionPreceeding(obj)
            res=obj.getStateFractionPreceeding( ...
                categorical({'SWS','REM'}), ...
                categorical({'A-WAKE','Q-WAKE'}) ...
                );
            res.sleepdur=res.interest;
            res.awakedur=res.rest;
            res.sum=res.awakedur+res.sleepdur;
            res.sleepFraction=res.sleepdur./res.sum;
        end
    end
end

