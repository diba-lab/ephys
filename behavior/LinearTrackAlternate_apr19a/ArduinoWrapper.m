classdef ArduinoWrapper < Singleton
    %ARDUINOWRAPPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        arduino
    end
    
    methods  (Access=private)
        function obj = ArduinoWrapper()
            %ARDUINOWRAPPER Construct an instance of this class
            %   Detailed explanation goes here
        obj.arduino = arduino;
        end
        
    end
    methods(Static)
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = ArduinoWrapper();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        function arduino=getArduino(obj)
            arduino=obj.arduino;
        end
    end
end

