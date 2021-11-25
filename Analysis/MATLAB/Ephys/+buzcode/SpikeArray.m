classdef SpikeArray
    %SPIKEARRAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Spike
    end
    
    methods
        function obj = SpikeArray(spike)
            %SPIKEARRAY Construct an instance of this class
            %   Detailed explanation goes here
            obj.Spike = spike;
        end
        
        function obj = plus(obj,spikeArray)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            spkA=obj.Spike;
            spkB=spikeArray.Spike;
            if strcmp(spkA.basename, spkB.basename)
                spkR.basename=spkA.basename;
                spkR.ids=[spkA.ids spkB.ids];
                spkR.ts=[spkA.ts spkB.ts];
                spkR.times=[spkA.times spkB.times];
                spkR.cluID=[spkA.cluID spkB.cluID];
                spkR.maxWaveformCh=[spkA.maxWaveformCh spkB.maxWaveformCh];
                spkR.maxWaveformCh1=[spkA.maxWaveformCh1 spkB.maxWaveformCh1];
                spkR.phy_amp=[spkA.phy_amp spkB.phy_amp];
                spkR.total=[spkA.total spkB.total];
                spkR.amplitudes=[spkA.amplitudes spkB.amplitudes];
                spkR.numcells=spkA.numcells+spkB.numcells;
                spkR.UID=[spkA.UID max(spkA.UID)+spkB.UID];
                spkR.sr=spkA.sr;
                spkR.shankID=[spkA.shankID spkB.shankID];
                spkR.rawWaveform=[spkA.rawWaveform spkB.rawWaveform];
                spkR.filtWaveform=[spkA.filtWaveform spkB.filtWaveform];
                spkR.rawWaveform_all=[spkA.rawWaveform_all spkB.rawWaveform_all];
                spkR.rawWaveform_std=[spkA.rawWaveform_std spkB.rawWaveform_std];
                spkR.filtWaveform_all=[spkA.filtWaveform_all spkB.filtWaveform_all];
                spkR.filtWaveform_std=[spkA.filtWaveform_std spkB.filtWaveform_std];
                spkR.timeWaveform=[spkA.timeWaveform spkB.timeWaveform];
                spkR.timeWaveform_all=[spkA.timeWaveform_all spkB.timeWaveform_all];
                spkR.peakVoltage=[spkA.peakVoltage spkB.peakVoltage];
                spkR.channels_all=[spkA.channels_all spkB.channels_all];
                spkR.peakVoltage_sorted=[spkA.peakVoltage_sorted spkB.peakVoltage_sorted];
                spkR.maxWaveform_all=[spkA.maxWaveform_all spkB.maxWaveform_all];
                spkR.peakVoltage_expFitLengthConstant=[spkA.peakVoltage_expFitLengthConstant ...
                    spkB.peakVoltage_expFitLengthConstant];
                spkR.processinginfo=spkA.processinginfo;
                obj.Spike=spkR;
            else
                return
            end
        end
        function save(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            spikes=obj.Spike;
            save(fullfile(spikes.basepath, [spikes.basename '.spikes.cellinfo.mat']),'spikes')
        end
    end
end

