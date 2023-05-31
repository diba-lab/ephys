classdef ThetaPeak
    %THETAPEAK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Signal
        CF
        Power
        fooof
        Bouts
        Speed
        EMG
        Info
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
            if ~isempty(thpk)&&~isempty(obj.Signal)&&~isempty(thpk.Signal)...
                    &&~isempty(thpk.Signal)
                    thpkres=obj;
                    thpkres.Signal=thpkres.Signal+thpk.Signal;
                    thpkres.CF=thpkres.CF+ thpk.CF;
                    thpkres.Power=thpkres.Power+thpk.Power;
                    thpkres.Bouts=[thpkres.Bouts;thpk.Bouts];
                    try
                        if thpk.Speed.getSampleRate~=thpkres.Speed.getSampleRate
                            thpk.Speed=thpk.Speed.getDownSampled( ...
                                thpkres.Speed.getSampleRate);
                        end
                        thpkres.Speed=thpkres.Speed+thpk.Speed;
                        thpkres.EMG=thpkres.EMG+thpk.EMG;
                    catch
                    end
            elseif ~isempty(obj.Signal)
                thpkres=obj;
            elseif ~isempty(thpk)&&~isempty(thpk.Signal)
                thpkres=thpk;
            else
                thpkres=obj;
            end
            thpkres.fooof=[];
        end
        function cmp=compare(obj,thpk)
            if ~isempty(thpk)&&~isempty(obj.Signal)&&~isempty(thpk.Signal)...
                    &&~isempty(thpk.Signal)
                thpkres=obj;
                [cmp.CF.h,cmp.CF.p,cmp.CF.ks2stat] =kstest2(...
                    thpkres.CF.Values,thpk.CF.Values);
                [cmp.Power.h,cmp.Power.p,cmp.Power.ks2stat] =kstest2( ...
                    thpkres.Power.Values,thpk.Power.Values);
                try
                    if thpk.Speed.getSampleRate~=thpkres.Speed.getSampleRate
                        thpk.Speed=thpk.Speed.getDownSampled( ...
                            thpkres.Speed.getSampleRate);
                    end
                    [cmp.Speed.h,cmp.Speed.p,cmp.Speed.ks2stat]=...
                        kstest2(thpkres.Speed.Values,thpk.Speed.Values);
                    [cmp.EMG.h,cmp.EMG.p,cmp.EMG.ks2stat] =kstest2( ...
                        thpkres.EMG.Values,thpk.EMG.Values);
                catch
                end
            end
        end
        function plotCF(obj)
            ax=gca;
            xlim=[5 9];
            thpkcf_fd=obj.CF.getMedianFiltered(1,'omitnan','truncate' ...
                ).getMeanFiltered(1);
            colors=linspecer(2);
            switch thpkcf_fd.getInfo.Condition
                case 'NSD'
                    info=1;
                case 'SD'
                    info=2;
            end
            h=histogram(thpkcf_fd.getValues,linspace(xlim(1),xlim(2),50), ...
                'Normalization','pdf');hold on;
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
            ax.YLim=[0 1];
            t=text(xlim(2),ax.YLim(2),sprintf('%.1fm',minutes( ...
                thpkcf_fd.getLength)));
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
            grid on
        end
        function plotSpeed(obj)
            ax=gca;
            xlim=[0 30];
            thpkcf_fd=obj.Speed.getMedianFiltered(.2,'omitnan','truncate' ...
                ).getMeanFiltered(.5);
            colors=linspecer(2);
            switch thpkcf_fd.getInfo.Condition
                case 'NSD'
                    info=1;
                case 'SD'
                    info=2;
            end
            xedge=linspace(xlim(1),xlim(2),51);
            x=linspace(xlim(1),xlim(2),50);
            h=histogram(thpkcf_fd.getValues,xedge,'Normalization','pdf');hold on;
            h.FaceAlpha=.5;
            h.FaceColor=colors(double(info),:);
            h.LineStyle='none';
            y = h.Values;
            p1=plot(x,y);
            p1.Color=colors(double(info),:);
            p1.LineWidth=2.5;
            l=xline(median(y));
            l.LineStyle='-';
            l.LineWidth=2.5;
            l.Color=colors(double(info),:)/2;
            text(median(y),0,sprintf('%.2f',median(y)));    
            ax.XLim=xlim;%bandFreq;
            ax.YLim=[0 .5];
            t=text(xlim(2),ax.YLim(2),sprintf('%.1fm',minutes(thpkcf_fd.getLength)));
            t.Color=colors(double(info),:)/2;
            t.HorizontalAlignment='right';
            switch info
                case 1
                    t.VerticalAlignment='bottom';
                case 2
                    t.VerticalAlignment='top';
            end
            xlabel('Speed (cm/s)');
            ylabel('pdf');
            ax.View=[90 -90];
            grid on
        end
        function plotCF3(obj)
            ax=gca;
            xlim=[5 9];
            thpkcf_fd=obj.CF.getMedianFiltered(1,'omitnan','truncate' ...
                ).getMeanFiltered(1);
            colors=linspecer(3);
            switch thpkcf_fd.getInfo.Condition
                case 'CTRL'
                    info=1;
                case 'ROL'
                    info=2;
                case 'OCT'
                    info=3;
            end
            h=histogram(thpkcf_fd.getValues,linspace(xlim(1),xlim(2),50), ...
                'Normalization','pdf');hold on;
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
            ax.YLim=[0 1];
            t=text(xlim(2),ax.YLim(2),sprintf('%.1fm',minutes( ...
                thpkcf_fd.getLength)));
            t.Color=colors(double(info),:)/2;
            t.HorizontalAlignment='right';
            switch info
                case 1
                    t.VerticalAlignment='bottom';
                case 2
                    t.VerticalAlignment='middle';
                case 3
                    t.VerticalAlignment='top';
            end
            xlabel('Frequency (Hz)');
            ylabel('pdf');
            ax.View=[90 -90];
            grid on
        end
        function plotPW3(obj)
            ax=gca;
            xlim=[50 250];
            thpkcf_fd=obj.Power.getMedianFiltered(1,'omitnan','truncate' ...
                ).getMeanFiltered(1);
            colors=linspecer(3);
            switch thpkcf_fd.getInfo.Condition
                case 'CTRL'
                    info=1;
                case 'ROL'
                    info=2;
                case 'OCT'
                    info=3;
            end
            h=histogram(thpkcf_fd.getValues,linspace(xlim(1),xlim(2),50), ...
                'Normalization','pdf');hold on;
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
            ax.YLim=[0 .02];
            t=text(xlim(2),ax.YLim(2),sprintf('%.1fm',minutes( ...
                thpkcf_fd.getLength)));
            t.Color=colors(double(info),:)/2;
            t.HorizontalAlignment='right';
            switch info
                case 1
                    t.VerticalAlignment='bottom';
                case 2
                    t.VerticalAlignment='middle';
                case 3
                    t.VerticalAlignment='top';
            end
            xlabel('Power');
            ylabel('pdf');
            ax.View=[90 -90];
            grid on
        end
        function l=plotPW(obj)
            ax=gca;
            xlim=[50 500];
            thpkcf_fd=obj.Power.getMedianFiltered(1,'omitnan','truncate' ...
                ).getMeanFiltered(1);
            colors=linspecer(2);
            switch thpkcf_fd.getInfo.Condition
                case 'NSD'
                    info=1;
                case 'SD'
                    info=2;
            end
            h=histogram(thpkcf_fd.getValues,linspace(xlim(1),xlim(2),50), ...
                'Normalization','pdf');hold on;
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
            ax.YLim=[0 .01];
            t=text(xlim(2),ax.YLim(2),sprintf('%.1fm.',minutes( ...
                thpkcf_fd.getLength)));
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
            grid on
        end
        function [table1]=plotDurationFrequency(obj,ax,color)
            if ~exist('ax','var')
                ax=gca;
            end
            valf=obj.CF.getValues;
            valp=obj.Power.getValues;
            vals=obj.fooof.Info.episode.getValues;
            obj.Bouts=obj.Bouts;
            freqarrs=neuro.basic.Oscillation.empty(numel(obj.Bouts)-1, 0);
            powarrs=neuro.basic.Oscillation.empty(numel(obj.Bouts)-1, 0);
            signal1=neuro.basic.Oscillation.empty(numel(obj.Bouts)-1, 0);
            for ibout=1:(numel(obj.Bouts)-1)
                boutSampleLow=[obj.Bouts(ibout,:).start obj.Bouts(ibout+1, ...
                    :).start]*obj.CF.getSampleRate;
                boutSampleLow(1)=boutSampleLow(1)+1;
                boutSampleHigh=[obj.Bouts(1,ibout) obj.Bouts(1,ibout+1)]*...
                    obj.fooof.Info.episode.getSampleRate;
                boutSampleHigh(1)=boutSampleHigh(1)+1;
                try
                    CF1=neuro.basic.Oscillation(valf(1,boutSampleLow(1): ...
                        boutSampleLow(2)),obj.CF.getSampleRate);
                    PW1=neuro.basic.Oscillation(valp(1,boutSampleLow(1): ...
                        boutSampleLow(2)),obj.Power.getSampleRate);
                    S1=neuro.basic.Oscillation(vals(1,boutSampleHigh(1): ...
                        boutSampleHigh(2)),obj.fooof.Info.episode.getSampleRate);
                catch
                    if boutSampleLow(2)>numel(valf)
                        CF1=neuro.basic.Oscillation(valf(1,boutSampleLow(1): ...
                            numel(valf)),obj.CF.getSampleRate);
                        PW1=neuro.basic.Oscillation(valp(1,boutSampleLow(1): ...
                            numel(valp)),obj.Power.getSampleRate);
                        S1=neuro.basic.Oscillation(vals(1,boutSampleHigh(1): ...
                            numel(vals)),obj.fooof.Info.episode.getSampleRate);
                    end
                end
                vals1=CF1.getValues;
                vals2=PW1.getValues;
                vals3=S1.getValues;
                vals1(isnan(vals1))=[];
                vals2(isnan(vals2))=[];
                vals3(isnan(vals3))=[];
                CFmeans(ibout)=mean(vals1);
                PWmeans(ibout)=mean(vals2);
                Smeans(ibout)=mean(vals3);
                freqarrs(ibout)=CF1;
                powarrs(ibout)=PW1;
                signal1(ibout)=S1;
            end
            durations=diff(obj.Bouts);
            if strcmpi(obj.fooof.Info.Condition,'NSD')
                cond=ones(size(durations))*1;
            else
                cond=ones(size(durations))*2;
            end
            z=ones(size(durations))*double(obj.fooof.Info.SubBlock);
%             s=scatter3(durations,CFmeans,z,10,color,"filled");
%             s.MarkerFaceAlpha=.5;
            table1=table(durations',CFmeans',z',cond',freqarrs',powarrs', ...
                signal1', ...
                'VariableNames',{'Duration','Frequency','SubBlock', ...
                'Condition','Array','PowerArray','Signal'});
        end
        function [table1]=plotDurationFrequency3(obj,ax,color)
            if ~exist('ax','var')
                ax=gca;
            end
            valf=obj.CF.getValues;
            valp=obj.Power.getValues;
            vals=obj.fooof.Info.episode.getValues;
            obj.Bouts=obj.Bouts;
            freqarrs=neuro.basic.Oscillation.empty(numel(obj.Bouts)-1, 0);
            powarrs=neuro.basic.Oscillation.empty(numel(obj.Bouts)-1, 0);
            signal1=neuro.basic.Oscillation.empty(numel(obj.Bouts)-1, 0);
            for ibout=1:(numel(obj.Bouts)-1)
                boutSampleLow=[obj.Bouts(1,ibout) obj.Bouts(1,ibout+1)]*...
                    obj.CF.getSampleRate;
                boutSampleLow(1)=boutSampleLow(1)+1;
                boutSampleHigh=[obj.Bouts(1,ibout) obj.Bouts(1,ibout+1)]*...
                    obj.fooof.Info.episode.getSampleRate;
                boutSampleHigh(1)=boutSampleHigh(1)+1;
                try
                CF1=neuro.basic.Oscillation(valf(1,boutSampleLow(1): ...
                    boutSampleLow(2)),obj.CF.getSampleRate);
                PW1=neuro.basic.Oscillation(valp(1,boutSampleLow(1): ...
                    boutSampleLow(2)),obj.Power.getSampleRate);
                S1=neuro.basic.Oscillation(vals(1,boutSampleHigh(1): ...
                    boutSampleHigh(2)),obj.fooof.Info.episode.getSampleRate);
                catch
                    if boutSampleLow(2)>numel(valf)
                        CF1=neuro.basic.Oscillation(valf(1,boutSampleLow(1): ...
                            numel(valf)),obj.CF.getSampleRate);
                        PW1=neuro.basic.Oscillation(valp(1,boutSampleLow(1): ...
                            numel(valp)),obj.Power.getSampleRate);
                        S1=neuro.basic.Oscillation(vals(1,boutSampleHigh(1): ...
                            numel(vals)),obj.fooof.Info.episode.getSampleRate);
                    end
                end
                vals1=CF1.getValues;
                vals2=PW1.getValues;
                vals3=S1.getValues;
                vals1(isnan(vals1))=[];
                vals2(isnan(vals2))=[];
                vals3(isnan(vals3))=[];
                CFmeans(ibout)=mean(vals1);
                PWmeans(ibout)=mean(vals2);
                Smeans(ibout)=mean(vals3);
                freqarrs(ibout)=CF1;
                powarrs(ibout)=PW1;
                signal1(ibout)=S1;
            end
            durations=diff(obj.Bouts);
            switch obj.fooof.Info.Condition
                case 'CTRL'
                cond=ones(size(durations))*1;
                case 'ROL'
                cond=ones(size(durations))*2;
                case 'OCT'
                cond=ones(size(durations))*3;
            end
            z=ones(size(durations))*double(obj.fooof.Info.SubBlock);
%             s=scatter3(durations,CFmeans,z,10,color,"filled");
%             s.MarkerFaceAlpha=.5;
            table1=table(durations',CFmeans',z',cond',freqarrs',powarrs',signal1', ...
                'VariableNames',{'Duration','Frequency','SubBlock', ...
                'Condition','Array','PowerArray','Signal'});
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

