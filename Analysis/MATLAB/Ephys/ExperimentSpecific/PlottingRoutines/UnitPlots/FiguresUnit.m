classdef FiguresUnit
    %FIGURESUNIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        UnitListFile
        SpikeArrays
    end
    
    methods
        function obj = FiguresUnit()
            %FIGURESUNIT Construct an instance of this class
            %   Detailed explanation goes here
            obj.UnitListFile='/home/mdalam/Downloads/Analysis_code/diba-ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/UnitList.txt';
            sf=SpikeFactory.instance;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessions=unique(list.SESSIONNO);
            for ises=1:numel(sessions)
                ses=sessions(ises);
                cachefile=fullfile('/home/mdalam/Downloads/Analysis_code/diba-ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/cache',strcat('unitarray_ses',num2str(ses)));
                try
                    load(cachefile,'spikeArray')
                catch
                rowidx=list.SESSIONNO==ses;
                seslist=list(rowidx,:);
                for is=1:height(seslist)
                    afolder=seslist(is,:);
                    sfFolder=afolder.PATH{:};
                    try
                        spikeArray=spikeArray+sf.getSpykingCircusOutputFolder(sfFolder);
                    catch
                        spikeArray=sf.getSpykingCircusOutputFolder(sfFolder);
                    end
                end
                save(cachefile,'spikeArray');
                clear spikeArray
                end
                SpikeArrays(ises)=spikeArray;
            end
            obj.SpikeArrays=SpikeArrays;
        end
        
        function outputArg = plotFireRate(obj)
            sessions=obj.SpikeArrays;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessions1=unique(list.SESSIONNO);
            for ises=1:numel(sessions1)
                sublist=list(list.SESSIONNO==sessions1(ises),:);
                inj=unique(sublist.INJECTION);
                ani=unique(sublist.ANIMAL);
                sessionsstr(ises)=inj;
                legendstr(ises)=strcat(ani,'__',inj);
            end
            for ises=1:numel(sessions)
                sa=sessions(ises);
                fireRate=sa.getFireRate;
                ticd=fireRate.getTimeInterval;
                nst=datetime(date)+(ticd.getStartTime-ticd.getDate);
                ticd_n=TimeInterval(nst,ticd.getSampleRate,ticd.getNumberOfPoints);
                fireRate=fireRate.setTimeInterval(ticd_n);
                fireRate=fireRate.getMedianFiltered(seconds(minutes(30)));
                fireRate=fireRate.getMeanFiltered(seconds(minutes(20)));
                fireRate=fireRate./60;
                p1=fireRate.plot;hold on;
                p1.LineWidth=2;
                inj=sessionsstr{ises};
                p1.Color=SDColors.(inj).RGB;
                ps(ises)=p1;
            end
            legend(ps,legendstr)
            ylabel('Fire Rate (Hz)');
        end
    end
end

