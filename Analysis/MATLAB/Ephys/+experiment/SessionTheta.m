classdef SessionTheta < experiment.Session
    %SESSIONTHETA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = SessionTheta(varargin)
            %SESSIONTHETA Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                ses=varargin{1} ;
                fnames=fieldnames(ses);
                for ifn=1:numel(fnames)
                    obj.(fnames{ifn})=ses.(fnames{ifn});
                end
            end
        end
        
        function cht = getThetaChannel(obj)
            dlfp=obj.getDataLFP;
            ctdh=dlfp.getChannelTimeDataHard;
            sdd=dlfp.getStateDetectionData;
            ch=ctdh.getChannel(sdd.getThetaChannelID);
            cht=neuro.basic.ChannelTheta(ch);
        end
        function th = getThetaRatioBuzcode(obj)
            dlfp=obj.getDataLFP;
            sdd=dlfp.getStateDetectionData;
            th=sdd.getThetaRatio;
        end
        function sw = getSlowWaveBroadbandBuzcode(obj)
            dlfp=obj.getDataLFP;
            sdd=dlfp.getStateDetectionData;
            sw=sdd.getSW;
        end
        function emg = getEMG(obj)
            dlfp=obj.getDataLFP;
            sdd=dlfp.getStateDetectionData;
            emg=sdd.getEMG;
        end
        function spd = getSpeed(obj)
            pos=obj.getPosition;
            spd=pos.getSpeed;
        end
    end
end

