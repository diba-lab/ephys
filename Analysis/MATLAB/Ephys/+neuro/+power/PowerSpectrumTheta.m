classdef PowerSpectrumTheta < neuro.power.PowerSpectrum
    %POWERSPECTRUMTHETA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end

    methods
        function obj = PowerSpectrumTheta(powerSpectrum)
            %POWERSPECTRUMTHETA Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@neuro.power.PowerSpectrum(powerSpectrum.Power, ...
                powerSpectrum.Frequency)
        end

        function fooofr=getFooof(powerSpectrum,settings,f_range)
            % FOOOF settings
            if ~exist('settings','var')||isempty(settings)
                % Use theta defaults
                settings.peak_width_limts=[1,12];
                settings.max_n_peaks=10;
                settings.min_peak_height=0;
                settings.peak_threshold=2;
                settings.aperiodic_mode='knee';
                settings.verbose=false;
            else
                settings.aperiodic_mode=char(settings.aperiodic_mode);
            end
            if ~exist('f_range','var')
                f_range = [0, 40];
            end
            try
                fooof_results = fooof(powerSpectrum.Frequency, ...
                    powerSpectrum.Power, f_range, settings, true);
            catch ME
                if strcmp(ME.identifier,'MATLAB:undefinedVarOrClass')
                    setenv('LD_LIBRARY_PATH', '/home/ukaya/anaconda3/lib/libstdc++.so.6')
                    fooof_module = py.importlib.import_module('fooof');
                    fooof_results = fooof(powerSpectrum.Frequency, ...
                        powerSpectrum.Power, f_range, settings, true);
                elseif strcmp(ME.identifier,'MATLAB:Python:PyException')
                    throw(ME);
                end
            end
            fooofr=neuro.power.Fooof(fooof_results);
        end
    end
end

