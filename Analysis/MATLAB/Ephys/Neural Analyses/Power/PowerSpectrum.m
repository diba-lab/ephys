classdef PowerSpectrum <TimeFrequencyEnhance
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
        function fooofr=getFooof(powerSpectrum,settings,f_range)
            
            % FOOOF settings
            if ~exist('settings','var')
                settings = struct();  % Use defaults
            end
            if ~exist('f_range','var')
                f_range = [0, 250];
            end
            fooof_results = fooof(powerSpectrum.Frequency, powerSpectrum.Power, f_range, settings, true);

            fooofr=Fooof(fooof_results);
        end
        function freq=getPeak(powerSpectrum,f_range)
            [~,idx(1)]=min(abs(powerSpectrum.Frequency-f_range(1)));
            [~,idx(2)]=min(abs(powerSpectrum.Frequency-f_range(2)));
            idx=idx(1):idx(2);
            power=powerSpectrum.Power(idx);
            [pks,locs] = findpeaks(power,'SortStr','descend');
            freq=powerSpectrum.Frequency(locs(1));
        end
    end
end

