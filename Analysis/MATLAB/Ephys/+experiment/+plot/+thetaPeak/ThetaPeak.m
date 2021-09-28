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
            thpks=experiment.plot.thetaPeak.ThetaPeakCombined(obj);
            thpks=thpks+thpk;
        end
        function thpks=add(obj,thpk,num)
            thpks=experiment.plot.thetaPeak.ThetaPeakCombined(obj);
            thpks=thpks.add(thpk,num);
        end
        function thpkres=merge(obj,thpk)
            if ~isempty(thpk)&&~isempty(obj.Signal)&&~isempty(thpk.Signal)
                    thpkres=obj;
                    thpkres.Signal=thpkres.Signal.getEphysTimeSeries+thpk.Signal.getEphysTimeSeries;
                    thpkres.CF=thpkres.CF.getEphysTimeSeries+thpk.CF.getEphysTimeSeries;
                    thpkres.Power=thpkres.Power.getEphysTimeSeries+thpk.Power.getEphysTimeSeries;
            elseif ~isempty(obj.Signal)
                thpkres=obj;
            elseif ~isempty(thpk)&&~isempty(thpk.Signal)
                thpkres=thpk;
            else
                thpkres=obj;
            end
            thpkres.fooof=[];
        end
        function plotCF(obj)
            ax=gca;
            xlim=[5 10];
            thpkcf_fd=obj.CF.getMedianFiltered(1,'omitnan','truncate').getMeanFiltered(1);
            colors=linspecer(2);
            switch thpkcf_fd.getInfo.Condition
                case 'NSD'
                    info=1;
                case 'SD'
                    info=2;
            end
            params=obj.getParams.Fooof;
            bands=params.BandFrequencies;
            bandFreq=bands.theta;
            
            h=histogram(thpkcf_fd.getValues,linspace(xlim(1),xlim(2),50),'Normalization','pdf');hold on;
            h.FaceAlpha=.5;
            h.FaceColor=colors(double(info),:);
            h.LineStyle='none';
            pd = fitdist(thpkcf_fd.getValues','Kernel','Kernel','epanechnikov');
            x=linspace(xlim(1),xlim(2),50);
            y = pdf(pd,x);
            p1=plot(x,y);
            p1.Color=colors(double(info),:);
            p1.LineWidth=2.5;
            l=xline(pd.median);
            l.LineStyle='-';
            l.LineWidth=2.5;
            l.Color=colors(double(info),:)/2;
%             text(pd.median,0,sprintf('%.2f',pd.median));    
            ax.XLim=xlim;%bandFreq;
            t=text(xlim(2),ax.YLim(2),sprintf('%.1fm',minutes(thpkcf_fd.getLength)));
            t.Color=colors(double(info),:)/2;
            t.HorizontalAlignment='right';
            switch info
                case 1
                    t.VerticalAlignment='bottom';
                case 2
                    t.VerticalAlignment='top';
            end
            xlabel('Frequency (Hz)');
            ylabel('pdf');
            ax.View=[90 -90];
        end
        function l=plotPW(obj)
            ax=gca;
            xlim=[0 600];
            thpkcf_fd=obj.Power.getMedianFiltered(1,'omitnan','truncate').getMeanFiltered(1);
            colors=linspecer(2);
            switch thpkcf_fd.getInfo.Condition
                case 'NSD'
                    info=1;
                case 'SD'
                    info=2;
            end
            params=obj.getParams.Fooof;
            bands=params.BandFrequencies;
            bandFreq=bands.theta;
            h=histogram(thpkcf_fd.getValues,linspace(xlim(1),xlim(2),50),'Normalization','pdf');hold on;
            h.FaceAlpha=.5;
            h.FaceColor=colors(double(info),:);
            h.LineStyle='none';
            pd = fitdist(thpkcf_fd.getValues','Kernel','Kernel','epanechnikov');
            x=linspace(xlim(1),xlim(2),50);
            y = pdf(pd,x);
            p1=plot(x,y);
            p1.Color=colors(double(info),:);
            p1.LineWidth=2.5;
            l=xline(pd.mean);
            l.LineStyle='-';
            l.LineWidth=2.5;
            l.Color=colors(double(info),:)/2;
            ax.XLim=xlim;%bandFreq;
            t=text(xlim(2),ax.YLim(2),sprintf('%.1fm.',minutes(thpkcf_fd.getLength)));
            t.Color=colors(double(info),:)/2;
            t.HorizontalAlignment='right';
            switch info
                case 1
                    t.VerticalAlignment='bottom';
                case 2
                    t.VerticalAlignment='top';
            end
            xlabel('Power');
            ylabel('pdf');
            ax.View=[90 -90];
        end
        function S=getParams(~)
            sde=experiment.SDExperiment.instance.get;
            configureFileSWRRate=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','SWRRate.xml');
            S.SWRRate=readstruct(configureFileSWRRate);
            configureFileFooof=fullfile(sde.FileLocations.General.PlotFolder...
                ,filesep, 'Parameters','Fooof.xml');
            S.Fooof=readstruct(configureFileFooof);
            
        end
        
    end
end

