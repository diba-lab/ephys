classdef Fooof
    %FOOOF Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fooof_results
        Info
    end
    
    methods
        function obj = Fooof(fooof_results1)
            %FOOOF Construct an instance of this class
            %   Detailed explanation goes here
            if exist('fooof_results1','var')
                obj.fooof_results = fooof_results1;
            end
        end
        
        function fooofr=rerun(obj,settings,f_range)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            % FOOOF settings
            if ~exist('settings','var')
                settings = struct();  % Use defaults
            end
            if ~exist('f_range','var')
                f_range = [0, 250];
            end
            fooof_results = fooof(obj.fooof_results.freqs, obj.fooof_results.power_spectrum, f_range, settings, true);

            fooofr=Fooof(fooof_results);
        end
        function plot(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            fooof_plot(obj.fooof_results);
            hold on;
            obj.plotPeaks;
        end
        function plotLog(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            fooof_plot(obj.fooof_results,true)
            hold on;
            obj.plotPeaksLog;
        end
        function peaksr=getPeaksXY(obj)
            r=obj.fooof_results;
            peaks=r.peak_params;
            for ipeak=1:size(peaks,1)
                x=peaks(ipeak,1);
                rel=peaks(ipeak,2);
                [~,idx]=min(abs(r.freqs-x));
                base=r.ap_fit(idx);
                y=rel+base;
                peaksr(ipeak).x=x;
                peaksr(ipeak).y=y;
            end
            
        end
        function plotPeaks(obj)
            peaks=obj.getPeaksXY;
            for ipeak=1:numel(peaks)
                x=peaks(ipeak).x;
                y=peaks(ipeak).y;
                t=text(x,y,strcat('\leftarrow',sprintf('%.1f,%.1f',x,y)));
                t.Rotation=90;
            end
        end
        function plotPeaksLog(obj)
            peaks=obj.getPeaksXY;
            for ipeak=1:numel(peaks)
                x=log10(  peaks(ipeak).x);
                y=peaks(ipeak).y;
                t=text(x,y,strcat('\leftarrow',sprintf('%.1f,%.1f',x,y)));
                t.Rotation=90;
            end
        end
        function peakres=getPeak(obj,freqs,powers,bandwidth)
            peaks=obj.fooof_results.peak_params;
            idxall=true([size(peaks,1) 1]);
            try
                idxfreq=peaks(:,1)<freqs(2)&peaks(:,1)>freqs(1);
            catch
                idxfreq=idxall;
            end
            try
                idxpow=peaks(:,2)<powers(2)&peaks(:,2)>powers(1);
            catch
                idxpow=idxall;
            end
            try
                idxbw=peaks(:,3)<bandwidth(2)&peaks(:,3)>bandwidth(1);
            catch
                idxbw=idxall;
            end
            idxall=idxall & idxfreq & idxpow & idxbw;
            peaks1=peaks(idxall,:);
            peaksorted=sortrows(peaks1,2,'descend');%sort by power
            for ipeak=1:1
                peaks2=peaksorted(ipeak,:);
                try
                    peakres(ipeak).cf=peaks2(1);
                    peakres(ipeak).power=peaks2(2);
                    peakres(ipeak).bw=peaks2(3);
                catch
                    peakres(ipeak).cf=nan;
                    peakres(ipeak).power=nan;
                    peakres(ipeak).bw=nan;
                end
            end
        end
        function peakres=getPeaks(obj,freqs,powers,bandwidth)
            if ~isempty(obj.fooof_results)
                peaks=obj.fooof_results.peak_params;
                idxall=true([size(peaks,1) 1]);
                try
                    idxfreq=peaks(:,1)<freqs(2)&peaks(:,1)>freqs(1);
                catch
                    idxfreq=idxall;
                end
                try
                    idxpow=peaks(:,2)<powers(2)&peaks(:,2)>powers(1);
                catch
                    idxpow=idxall;
                end
                try
                    idxbw=peaks(:,3)<bandwidth(2)&peaks(:,3)>bandwidth(1);
                catch
                    idxbw=idxall;
                end
                idxall=idxall & idxfreq & idxpow & idxbw;
                peaks1=peaks(idxall,:);
                peaksorted=sortrows(peaks1,2,'descend');%sort by power
                for ipeak=1:(size(peaksorted,1))
                    peaks2=peaksorted(ipeak,:);
                    try
                        peakres(ipeak).cf=peaks2(1);
                        peakres(ipeak).power=peaks2(2);
                        peakres(ipeak).bw=peaks2(3);
                    catch
                        peakres(ipeak).cf=nan;
                        peakres(ipeak).power=nan;
                        peakres(ipeak).bw=nan;
                    end
                end
            else
                peakres=[];
            end
        end
    end
end

