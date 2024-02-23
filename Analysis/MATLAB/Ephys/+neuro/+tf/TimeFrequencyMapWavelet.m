classdef TimeFrequencyMapWavelet < neuro.tf.TimeFrequencyMap
    %TIMEFREQUENCYMAPWAVELET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = TimeFrequencyMapWavelet(...
                matrix, timePoints,frequencyPoints)
            %TIMEFREQUENCYMAPWAVELET Construct an instance of this class
            %   Detailed explanation goes here
            obj@neuro.tf.TimeFrequencyMap(matrix, timePoints,frequencyPoints)
%             obj.clim=[0 1];
        end
        
        function imsc = plot(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            abs1=ismember(varargin,{'Absolute','Abs','absolute','abs'} );
            varargin(abs1)=[];
            zt1=ismember(varargin,{'ZT','zt'});
            varargin(zt1)=[];
            s1=ismember(varargin,{'s','sec','second','seconds', ...
                'S','Sec','Second','Seconds'});
            varargin(s1)=[];
            h1=ismember(varargin,{'h','hours','H','Hours'});
            varargin(h1)=[];

            mat=(abs(obj.matrix));
            ticd=obj.timeIntervalCombined;
            if any(abs1)
                timepoints=ticd.getTimePointsInAbsoluteTimes;
            else
                tp=ticd.getTimePointsZT;
                if ~any(s1)
                    timepoints=hours(tp);
                else
                    timepoints=seconds(tp);
                end
            end
            imsc=imagesc(timepoints, obj.frequencyPoints,mat);
            ax=gca;
            ax.YDir='normal';
            ax.XLim=[min(timepoints) max(timepoints)];
            ax.YLim=[obj.frequencyPoints(1) obj.frequencyPoints(end)];
            m=mean2(mat);s=std2(mat);
            ax.CLim=[m-2*s m+2*s];
        end
        function phase = getPhase(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            va=angle(obj.matrix(ismember(obj.frequencyPoints,freq),:));
            phase=neuro.basic.Channel(num2str(freq),va,obj.timeIntervalCombined);
        end
        function power = getPower(obj,freq)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            va=abs(obj.matrix(ismember(obj.frequencyPoints,freq),:));
            if size(va,1)>1
                va=mean(va,1);
            end
            power=neuro.basic.Channel(num2str(freq),va,obj.timeIntervalCombined);
        end
    end
end

