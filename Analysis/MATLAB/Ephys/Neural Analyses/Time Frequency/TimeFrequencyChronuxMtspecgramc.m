classdef TimeFrequencyChronuxMtspecgramc < TimeFrequencyMethod
    %TIMEFREQUENCYPROPERTIESWAVELET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        movingWindow
        tapers
        pad
        Fs
        fpass
        err
    end
    
    methods
        function obj = TimeFrequencyChronuxMtspecgramc(frequencyInterests,...
                movingWindow, tapers, pad, err)
            %TIMEFREQUENCYPROPERTIESWAVELET Construct an instance of this class
            %   Detailed explanation goes here
            %       movingwin         (in the form [window winstep] i.e length of moving
%                                                 window and step size)
%                                                 Note that units here have
%                                                 to be consistent with
%                                                 units of Fs - required

            obj = obj@TimeFrequencyMethod(frequencyInterests);
            obj.fpass=frequencyInterests;
            obj.movingWindow=movingWindow;
            if nargin>4
                obj.tapers = tapers;
            else
            end
            if nargin>3
                obj.pad = pad;
            else
            end
            if nargin>2
                obj.err = err;
            else
            end
        end
        
        function aTimeFrequencyMap = execute(obj,...
                data, Fs)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            movingwin=obj.movingWindow;
            params.fpass=[obj.FrequencyInterest(1) obj.FrequencyInterest(end)];
            params.Fs=Fs;
            [matrix,t,f]=mtspecgramc(data,movingwin,params);
            aTimeFrequencyMap=TimeFrequencyMapChronuxMtspecgramc(...
                matrix, seconds(t), f);
        end
    end
end

