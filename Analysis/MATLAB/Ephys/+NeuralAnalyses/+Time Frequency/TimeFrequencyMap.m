classdef (Abstract) TimeFrequencyMap < Topography2D
    %TIMEFREQUENCYMAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        matrix
        timePoints
        frequencyPoints
        clim
        timeIntervalCombined
    end
    methods (Abstract)
    end
    
    methods
        function obj = TimeFrequencyMap(matrix, timePoints,frequencyPoints)
            %TIMEFREQUENCYMAP Construct an instance of this class
            %   Detailed explanation goes here

            obj@Topography2D(abs(matrix),timePoints, frequencyPoints);
            obj.timePoints=timePoints;
            obj.frequencyPoints=frequencyPoints;
            obj.matrix=matrix;
        end
        
        function obj = setTimePoints(obj,time)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.timePoints=time;
            obj=obj.setxBins(time);
        end
        function [mat, freq] = getSpectogramSamples(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mat=obj.matrix;
            freq=obj.frequencyPoints;
        end
        function [meanfreq] = getMeanFrequency(obj,freqRange)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            mat=10*log10( abs(obj.matrix));
            freq=obj.frequencyPoints;
            freqpoints=(freqRange(1)<freq)&(freqRange(2)>freq);
            meanfreq=mean(mat(:,freqpoints),2);
        end
        function [thpkfreq, thpkpower ] = getFrequencyBandPeak(obj,freqRange)
            mat=obj.matrix;
            freq=obj.frequencyPoints;
            thpkfreq=nan(1,size(mat,2));
            thpkpower=nan(1,size(mat,2));
            for it=1:size(mat,2)
                psd1=PowerSpectrum( abs(mat(:,it)),freq);
                [pk,pwr]=psd1.getPeak(freqRange);
                if ~isempty(pk)
                    thpkfreq(it)=pk;
                    thpkpower(it)=pwr;
                end
                
            end
            thpkfreq=EphysTimeSeries(thpkfreq,obj.getSampleRate);
            thpkpower=EphysTimeSeries(thpkpower,obj.getSampleRate);
        end
        function [obj] = setTimeintervalCombined(obj,ticd)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.timeIntervalCombined=ticd;
        end
        function [ticd] = getTimeintervalCombined(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ticd=obj.timeIntervalCombined;
        end
        function sr = getSampleRate(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ticd=obj.timeIntervalCombined;
            sr=ticd.getSampleRate;
        end

    end
end

