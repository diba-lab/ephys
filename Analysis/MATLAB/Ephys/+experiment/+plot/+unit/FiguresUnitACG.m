classdef FiguresUnitACG < experiment.plot.unit.FiguresUnit
    %FIGURESUNITACG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ACGs
    end
    
    methods
        function obj = FiguresUnitACG()
            %FIGURESUNITACG Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        
        function [] = plotACG(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/ACG/CA1');
            sas=obj.SpikeArrays;
            sf=experiment.SessionFactory;
            sesnos=obj.getSessionNos;
            blocks={'PRE','SD','TRACK','POST'};
            hours1{1}=[-3 0];
            hours1{2}=[0 1; 1 2; -2 -1; -1 0];
            hours1{3}=[0 1;1 2;2 3; 3 4; 4 5; 5 6]/6;
            hours1{3}=[0 6]/6;
            hours1{4}=[0 1;1 2;2 3;3 4];
            numtimeWindows=11;timeWindNo=1;
            try close(2); catch, end; f2=figure(2);f2.Units='pixels';f2.Position=[1441,1250,2558,400];
            for iblock=1:numel(blocks)
                timeframes=hours1{iblock};
                for ihours=1:size(hours1{iblock},1)
                    timeframe=timeframes(ihours,:);
                    for ises=1:numel(sesnos)
                        sesno=sesnos(ises);
                        ses=sf.getSessions(sesno);
                        sa=sas(ises);
                        sa_exp=experiment.SpikeArraySleepDeprivation(sa,ses);
                        sa_e_b1=sa_exp.getBlock(blocks{iblock});
                        sa_e_b2=sa_e_b1.getTimeFrameRelativeToBeginAndEndInDurations(hours(timeframe));
                        sa_e_b0=sa_e_b2.get();
                        sa_e_b1=sa_e_b2.get('CA1');
                        sa_e_b3=sa_e_b2.get('CA3');
                        sa_e_b=sa_e_b1;
                        [~,loc]=ismember({'SD','NSD'}, ses.SessionInfo.Condition);
                        loc=find(loc);
                        try
                            sa_sd_nsd(loc)=sa_sd_nsd(loc)+sa_e_b;
                        catch
                            sa_sd_nsd(loc)=sa_e_b;
                        end
                    end
                    acgsd=sa_sd_nsd(1).getAutoCorrelogram().getACGWithCountBiggerThan(30).getNormalized([.1 .15]);
                    
                    acgnsd=sa_sd_nsd(2).getAutoCorrelogram().getACGWithCountBiggerThan(30).getNormalized([.1 .15]);
                    clear sa_sd_nsd;
                    try close(1); catch, end; f=figure('Units','pixels','Position',[200 2022 1000 800]);
                    
                    subplot(2,2,3); sd=acgsd.plot;
                    title1=[blocks{iblock} ' SD ' num2str(timeframe)]; title(title1);
                    subplot(2,2,1); nsd=acgnsd.plot;
                    title1=[blocks{iblock} ' NSD ' num2str(timeframe)]; title(title1);
                    subplot(4,2,[4 6]);
                    
                    vs=violinplot([sd.freq; nsd.freq],[repmat({'SD '},size(sd.freq));repmat({'NSD'},size(nsd.freq))]);
                    v1=vs(1);
                    v1.ViolinColor=[0, 0.4470, 0.7410];
                    v2=vs(2);
                    v2.ViolinColor=[0.8500, 0.3250, 0.0980];
                    ax=gca;ax.YLim=[5 10];
                    ax.YGrid='on';
                    ax.YLabel.String='Frequency (Hz)';
                    title1=[blocks{iblock} num2str(timeframe)]; title(title1);
                    figure(f);pause(.3);
                    ff.save(matlab.lang.makeValidName(title1));
                    
                    figure(f2);
                    subplot(1,numtimeWindows,timeWindNo);timeWindNo=timeWindNo+1;
                                        
                    vs=violinplot([sd.freq; nsd.freq],[repmat({'SD '},size(sd.freq));repmat({'NSD'},size(nsd.freq))]);
                    v1=vs(1);
                    v1.ViolinColor=[0, 0.4470, 0.7410];
                    v2=vs(2);
                    v2.ViolinColor=[0.8500, 0.3250, 0.0980];
                    ax=gca;ax.YLim=[5 10];
                    ax.YGrid='on';
                    ax.YLabel.String='Frequency (Hz)';
                    title1=[blocks{iblock} num2str(timeframe)]; title(title1);
                end
            end
            ff.save('All-sd-nsd');
        end
    end
end

