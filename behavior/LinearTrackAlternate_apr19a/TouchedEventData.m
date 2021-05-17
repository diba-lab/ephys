classdef TouchedEventData < event.EventData
    properties
        SensorPin;
    end
    methods
        function obj = TouchedEventData(sensorPin)
            obj.SensorPin = sensorPin;
        end
        function sp = getSensorPin(obj)
            sp = obj.SensorPin;
        end
        
    end
end
