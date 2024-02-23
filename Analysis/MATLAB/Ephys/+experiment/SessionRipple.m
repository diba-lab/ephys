classdef SessionRipple < experiment.Session
    %SESSIONTHETA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        RippleChannels
        Ripples
    end
    
    methods
        function obj = SessionRipple(varargin)
            %SESSIONTHETA Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>0
                ses=varargin{1} ;
                fnames=fieldnames(ses);
                for ifn=1:numel(fnames)
                    obj.(fnames{ifn})=ses.(fnames{ifn});
                end
            end
            obj.RippleChannels=obj.getRippleChannels;
            obj.Ripples=obj.getRipples;
        end
        
        function chripples = getRippleChannels(obj)
            dlfp=obj.getDataLFP;
            ctdh=dlfp.getChannelTimeDataHard;
            chans=readstruct(fullfile(obj.getBasePath,'Parameters', ...
                'RippleDetection.xml'));
            fnames=fieldnames(chans.BestChannel);
            rippleEvents=obj.getRipples;
            chripples=neuro.basic.ChannelRipple.empty(numel(fnames),0);
            for ifn=1:numel(fnames)
                fname=fnames{ifn};
                ripChan(ifn)=chans.BestChannel.(fname);
            end
            ripChan=unique(ripChan);
            for ifn=1:numel(ripChan)
                ch=ctdh.getChannel(ripChan(ifn));
                chripples(ifn)=neuro.basic.ChannelRipple(ch);
                chripples(ifn).RippleEvents=rippleEvents;
            end
        end
        function [] = PlotRippleChannels(obj,window_interested)
            %%
            ripples0=obj.Ripples;
            ripples=ripples0.getWindow(window_interested);

            figure(4);clf;tiledlayout("vertical");
            rippleChannels=obj.RippleChannels;
            for ichan=1:numel(rippleChannels)
                rp1x=rippleChannels(ichan);
                rp1(ichan)=rp1x.getTimeWindow(window_interested);
                rp2(ichan)=rp1(ichan).getFilteredInRippleFrequency;
                rp2env(ichan)=rp2(ichan).getEnvelope;
                [rptf(ichan), tfm(ichan)]=rp1(ichan).getFrequencyRippleInstantaneous;
            end
            %%
            for ichan=1:numel(rippleChannels)
                ax_orig(ichan)=nexttile;
            end

            ax_env=nexttile;hold on
            for ichan=1:numel(rippleChannels)
                ax_tf(ichan)=nexttile;
            end
            linkaxes([ax_tf ax_env ax_orig],'x');
            linkaxes(ax_orig,'xy');

            colors=colororder;
            for ichan=1:numel(rippleChannels)
                axes(ax_orig(ichan));
                rp1(ichan).plot;hold on
                yyaxis("right")
                rp2(ichan).plot
                p=rp2env(ichan).plot;p.LineWidth=1.5;p.LineStyle="-";p.Color=colors(4,:);
                rp2env(ichan).Values=-rp2env(ichan).Values;
                p=rp2env(ichan).plot;p.LineWidth=1.5;p.LineStyle="-";p.Color=colors(4,:);
                rp2env(ichan).Values=-rp2env(ichan).Values;
                axes(ax_env);
                p=rp2env(ichan).plot;p.LineWidth=1.5;p.LineStyle="-";p.Color=colors(4,:);
                axes(ax_orig(ichan));
                ripples.plotWindowsTimeZt
                axes(ax_tf(ichan));
                tfm(ichan).plot; hold on
                ripples.plotWindowsTimeZt
                % rptf.CF.plot;
            end
            axes(ax_env);
            ripples.plotWindowsTimeZt

        end
    end
end

