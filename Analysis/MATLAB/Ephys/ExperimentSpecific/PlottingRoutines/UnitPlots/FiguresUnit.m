classdef FiguresUnit
    %FIGURESUNIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        UnitListFile
        Session_Block
        SpikeArrays
    end
    
    methods
        function obj = FiguresUnit()
            %FIGURESUNIT Construct an instance of this class
            %   Detailed explanation goes here
            obj.UnitListFile='/home/mdalam/Downloads/Analysis_code/diba-ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/UnitList.txt';
            obj.Session_Block='/home/mdalam/Downloads/Analysis_code/diba-ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/Ses_Block.txt';
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
            sessionInterests=[-hours(3) minutes(45) hours(4.5) hours(3)];
            ses_block=readtable(obj.Session_Block,'Delimiter',',');
            
            sessions=obj.SpikeArrays;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessions1=unique(list.SESSIONNO);
            for ises=1:numel(sessions1)
                sublist=list(list.SESSIONNO==sessions1(ises),:);
                inj=unique(sublist.INJECTION);
                ani=unique(sublist.ANIMAL);
                sessionsstr(ises)=inj; %#ok<AGROW>
                legendstr(ises)=strcat(ani,'__',inj); %#ok<AGROW>
                tbl=readtable(ses_block(ses_block.Session==sessions1(ises),:).BlockFile{:});
                block=SDBlocks(datetime(date),tbl);
                sess=block.getBlockNames;
                for iblock=1:numel(sess)
                    thebl=block.get(sess{iblock});
                    dur=sessionInterests(iblock);
                    if dur<0
                        thebl(1)=thebl(2)+dur;
                    else
                        thebl(2)=thebl(1)+dur;
                    end
                    blocks(:,iblock,ises)=thebl; %#ok<AGROW>
                end
            end
            try close(1); catch, end; figure(1);
            for ises=1:numel(sessions)
                subplot(numel(sessions),1,ises);ax=gca;
                sa=sessions(ises);
                [fireRatem fireRatee]=sa.getMeanFireRateQuintiles(5);
                for ibl=1:size(blocks,2)
                    boc=BlockOfChannels();
                    for iq=1:numel(fireRatem)
                        frmq=fireRatem{iq};
                        aBlockfrmq=frmq.getTimeWindow(blocks(:,ibl,ises)');
                        boc=boc.addChannel(aBlockfrmq);
                        freq=fireRatee{iq};
                        aBlockfreq=freq.getTimeWindow(blocks(:,ibl,ises)');
                        boc=boc.addChannel(aBlockfreq);
                    end
                    boc.plot;hold on;
                    bocs{ibl}=boc;
                end
                ax.YScale='log';
                ax.YLim=[10e-4 10];
                ylabel('Firing Rate (Hz)');
                
            end
            
                ticd=fireRate.getTimeInterval;
                nst=datetime(date)+(ticd.getStartTime-ticd.getDate);
                ticd_n=TimeInterval(nst,ticd.getSampleRate,ticd.getNumberOfPoints);
                fireRate=fireRate.setTimeInterval(ticd_n);
                fireRate=fireRate.getMedianFiltered(seconds(minutes(10)));
                fireRate=fireRate.getMeanFiltered(seconds(minutes(10)));
                fireRate=fireRate./60;
                p1=fireRate.plot;hold on;
                p1.LineWidth=2;
                inj=sessionsstr{ises};
                p1.Color=SDColors.(inj).RGB;
                ps(ises)=p1;
%             end
            legend(ps,legendstr)
            ylabel('Fire Rate (Hz)');
        end
    end
end

