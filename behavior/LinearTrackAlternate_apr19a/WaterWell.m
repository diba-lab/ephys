classdef WaterWell < handle
    %WATERWELL Summary of this class goes here
    %   Detailed explanation goes here
    events
        Touched
        Watered
    end
    
    properties (Access=private)
        isActive1
        sensorPin
        motorPin
        configFile
    end
    
    methods
        function obj = WaterWell(sensorPin, motorPin, configFile)
            obj.sensorPin = sensorPin;
            obj.motorPin = motorPin;
            
            obj.configFile = configFile;
            obj.isActive1=true;
            ArduinoWrapper.instance.getArduino.writeDigitalPin(obj.motorPin, 0);
            fprintf('Water Well Created.\n  Sense Pin: %s\n  Motor Pin: %s.\n',sensorPin,motorPin)
        end
        
        function []=checkAndIfWater(obj)
            theArduino=ArduinoWrapper.instance.getArduino;
            sense=theArduino.readDigitalPin(obj.sensorPin);
            if sense
                te=TouchedEventData(obj.sensorPin);
                obj.notify('Touched',te);
                if obj.isActive
                    T=readtable(obj.configFile);
                    ind1=strcmpi(T.MotorPin,obj.motorPin);
                    amountOfWaterProvidedAtATimeInMs=T(ind1,:).WaterAmount;
                    theArduino.writeDigitalPin(obj.motorPin, 1);
                    pause(amountOfWaterProvidedAtATimeInMs/1000);
                    theArduino.writeDigitalPin(obj.motorPin,0);
                    we=WateredEventData(obj.motorPin,amountOfWaterProvidedAtATimeInMs);
                    obj.notify('Watered',we);
                end
                sense=theArduino.readDigitalPin(obj.sensorPin);
                while sense
                    pause(.01);
                    sense=theArduino.readDigitalPin(obj.sensorPin);
                end
            end
        end
        
        function [obj]=activate(obj)
            obj.isActive1=true;
        end
        
        function [obj]=deactivate(obj)
            obj.isActive1=false;
        end
        function [isActive]=isActive(obj)
            isActive=obj.isActive1;
        end
        
        function [] = water(obj)
            theArduino.writeDigitalPin(obj.motorPin,1);
            startat(t,fTime);
            theArduino.writeDigitalPin(obj.motorPin,1);
            obj.notify('Watered');
        end
    end
end

