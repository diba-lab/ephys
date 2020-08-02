classdef PowerSpectrum <TimeFrequencyEnhance
    %POWERSPECTRUM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Frequency
        Power
        InfoNum
        InfoName
        SignalLenght
    end
    
    methods
        function obj = PowerSpectrum(power,frequency)
            %POWERSPECTRUM Construct an instance of this class
            %   Detailed explanation goes here
            obj.Frequency = frequency;
            obj.Power = power;
        end
        
        function [p1] = plot(obj,frequencyFrame,ylim)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            p1=plot(obj.Frequency,pow2db(obj.Power));
            ax=gca;
            if nargin>1
                try
                    ax.XLim=frequencyFrame;
                catch
                end
            else
                ax.XLim=[obj.Frequency(1) obj.Frequency(end)];
            end
            
            try
                ax.YLim=ylim;
            catch
            end
            
            grid on
            xlabel('Frequency (Hz)')
            ylabel('Power Spectrum (dB)')
            title('Default Frequency Resolution')
        end
        function [p1] = semilogx(obj,frequencyFrame,ylim)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            p1=semilogx(obj.Frequency,pow2db(obj.Power));
            ax=gca;
            if nargin>1
                try
                    ax.XLim=frequencyFrame;
                catch
                end
            else
                ax.XLim=[obj.Frequency(1) obj.Frequency(end)];
            end
            
            try
                ax.YLim=ylim;
            catch
            end
            
            grid on
            xlabel('Frequency (Hz)')
            ylabel('Power Spectrum (dB)')
            title('Default Frequency Resolution')
        end
        function obj=setInfoNumAndName(obj,num,name)
            obj.InfoNum=num;
            obj.InfoName=name;
        end
        function obj=setSignalLength(obj,proportion)
            obj.SignalLenght=proportion;
        end
        function [str]=print(obj)
            fprintf('%d, %s\n',obj.InfoNum, obj.InfoName);
            str=sprintf('%d, %s\n',obj.InfoNum, obj.InfoName);
            
        end
    end
end

