classdef SessionJ <experiment.Session
    %SESSIONJ Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = SessionJ(varargin)
            %SESSIONJ Construct an instance of this class
            %   Detailed explanation goes here
            obj@experiment.Session(varargin{:})
        end

        function obj = setSleepCondition(obj,condition)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            sessionInfoStruct=obj.SessionInfo;
            sessionInfoStruct.Condition=condition;
            obj=obj.setSessionInfo(sessionInfoStruct);
        end
        function obj = setInjection(obj,injection)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            sessionInfoStruct=obj.SessionInfo;
            sessionInfoStruct.Injection=injection;
            obj=obj.setSessionInfo(sessionInfoStruct);
        end
    end
end

