classdef WateredEventData < event.EventData
    properties
        MotorPin;
        AmountOfWater;
    end
    methods
        function obj = WateredEventData(motorPin,AmountOfWater)
            obj.MotorPin = motorPin;
            obj.AmountOfWater = AmountOfWater;
        end
        
        function mp = getMotorPin(obj)
            mp=obj.MotorPin;
        end
        
        function aow = getAmountOfWater(obj)
            aow=obj.AmountOfWater;
        end
        
    end
end
