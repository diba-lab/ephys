classdef StateDetection
    %SLEEPDETECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        LFPFile
        StateDetectionMethod
        ssBuzCode
    end
    
    methods
        function obj = StateDetection()
        end
        
        function [] = plotSpectograms(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            swFFTspec=obj.getswFFTspec;
            swFFTfreqs=obj.getswFFTfreqs;
            thFFTspec=obj.getthFFTspec;
            thFFTfreqs=obj.getthFFTfreqs;
            [zFFTspec,mu,sig] = zscore(log10(swFFTspec)');
            [~,mu_th,sig_th] = zscore(log10(thFFTspec)');
            t_clus=obj.gett_clus;
            imagesc(t_clus,log2(swFFTfreqs),log10(swFFTspec))
            axis xy
            set(gca,'YTick',(log2([1 2 4 8 16 32 64 128])))
            set(gca,'YTickLabel',{'1','2','4','8','16','32','64','128'})
            caxis([3.5 6.5])
            caxis([min(mu)-2.5*max(sig) max(mu)+2.5*max(sig)])
            xlim(viewwin)
            colorbar('east')
            ylim([log2(swFFTfreqs(1)) log2(swFFTfreqs(end))+0.2])
            set(gca,'XTickLabel',{})
            ylabel({'swLFP','f (Hz)'})
            title([recordingname,': State Scoring Results']);
        end
        function swFFTspec = getswFFTspec(obj)
            ss=obj.ssBuzCode;
            swFFTspec=ss.detectorinfo.StatePlotMaterials.swFFTspec;
        end
        function swFFTfreqs = getswFFTfreqs(obj)
            ss=obj.ssBuzCode;
            swFFTfreqs=ss.detectorinfo.StatePlotMaterials.swFFTfreqs;
        end
        function thFFTspec = getthFFTspec(obj)
            ss=obj.ssBuzCode;
            thFFTspec=ss.detectorinfo.StatePlotMaterials.thFFTspec;
        end
        function thFFTfreqs = getthFFTfreqs(obj)
            ss=obj.ssBuzCode;
            thFFTfreqs=ss.detectorinfo.StatePlotMaterials.thFFTfreqs;
        end
        function t_clus = gett_clus(obj)
            ss=obj.ssBuzCode;
            t_clus=ss.detectorinfo.detectionparms.SleepScoreMetrics.t_clus;
        end
        
       
        
    end
end

