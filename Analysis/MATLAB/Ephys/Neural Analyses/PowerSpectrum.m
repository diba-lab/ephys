classdef PowerSpectrum
    %POWERSPECTRUM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Frequency
        Power
    end
    
    methods
        function obj = PowerSpectrum(power,frequency)
            %POWERSPECTRUM Construct an instance of this class
            %   Detailed explanation goes here
            obj.Frequency = frequency;
            obj.Power = power;
        end
        
        function [p1] = plot(obj,frequencyFrame)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            p1=plot(obj.Frequency,pow2db(obj.Power));
            ax=gca;
            if nargin>1
            ax.XLim=frequencyFrame;
            ax.YLim=[20 60];
            else
                ax.XLim=[obj.Frequency(1) obj.Frequency(end)];
            end
            grid on
            xlabel('Frequency (Hz)')
            ylabel('Power Spectrum (dB)')
            title('Default Frequency Resolution')
        end
    end
end

