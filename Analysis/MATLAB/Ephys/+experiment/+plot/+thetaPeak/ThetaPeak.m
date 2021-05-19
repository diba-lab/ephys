classdef ThetaPeak
    %THETAPEAK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Signal
        CF
        Power
        fooof
    end
    
    methods
        function obj = ThetaPeak(CF,PW,fooof)
            %THETAPEAK Construct an instance of this class
            %   Detailed explanation goes here
            try
                obj.CF = CF;
            catch
            end
            try
                obj.Power=PW;
            catch
            end
            try
                obj.fooof=fooof;
            catch
            end
        end
        
        function obj = addFooof(obj,fooof)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.fooof=fooof;
        end
        function obj = addSignal(obj,sig)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Signal=sig;
        end
        function thpks=plus(obj,thpk)
            thpks=ThetaPeakCombined(obj);
            thpks=thpks+thpk;
        end
        function thpkres=merge(obj,thpk)
            if ~isempty(obj.Signal)&&~isempty(thpk.Signal)
                    thpkres=obj;
                    thpkres.Signal=thpkres.Signal.getEphysTimeSeries+thpk.Signal.getEphysTimeSeries;
                    thpkres.CF=thpkres.CF.getEphysTimeSeries+thpk.CF.getEphysTimeSeries;
                    thpkres.Power=thpkres.Power.getEphysTimeSeries+thpk.Power.getEphysTimeSeries;
            elseif ~isempty(obj.Signal)
                thpkres=obj;
            elseif ~isempty(thpk.Signal)
                thpkres=thpk;
            else
                thpkres=obj;
            end
            thpkres.fooof=[];
        end
        function plotCF(obj)
            ax=gca;
            thpkcf_fd=obj.CF.getMedianFiltered(1,'omitnan','truncate').getMeanFiltered(1);
            colors=linspecer(2);
            info=thpkcf_fd.getInfo.Condition;
            params=obj.getParams.Fooof;
            bands=params.BandFrequencies;
            bandFreq=bands.theta;
            
            h=histogram(thpkcf_fd.getValues,50,'Normalization','pdf');hold on;
            h.FaceAlpha=.5;
            h.FaceColor=colors(double(info),:);
            pd = fitdist(thpkcf_fd.getValues','Kernel','Kernel','epanechnikov');
            x=linspace(5,10,50);
            y = pdf(pd,x);
            p1=plot(x,y);
            p1.Color=colors(double(info),:);
            p1.LineWidth=2.5;
            l=xline(pd.median);
            l.LineStyle='--';
            l.LineWidth=2.5;
            l.Color=colors(double(info),:);
%             text(pd.median,0,sprintf('%.2f',pd.median));    
            ax.XLim=[5 10];%bandFreq;
            xlabel('Frequency (Hz)');
            ylabel('pdf');
            try
                peaks1=obj.fooof.getPeaks(bandFreq);
                for ipeak=1:numel(peaks1)
                    peak1=peaks1(ipeak);
                    l=xline(peak1.cf);
                    l.LineStyle='--';
                    l.Color='k';
                    if ipeak==1
                        l.LineWidth=2.5;
                    end
                end
            catch
            end
            ax.View=[90 -90];
        end
        function plotPW(obj)
            ax=gca;
            thpkcf_fd=obj.Power.getMedianFiltered(1,'omitnan','truncate').getMeanFiltered(1);
            
            histogram((thpkcf_fd.getValues));
            xlabel('Power');
            ylabel('Count');
            ax.XLim=[0 400];
        end
        function S=getParams(~)
            sde=SDExperiment.instance.get;
            configureFileSWRRate=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','SWRRate.xml');
            S.SWRRate=readstruct(configureFileSWRRate);
            configureFileFooof=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','Fooof.xml');
            S.Fooof=readstruct(configureFileFooof);
            
        end
        
    end
end

