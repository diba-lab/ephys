classdef FiguresUnit
    %FIGURESUNIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Parameters
        UnitListFile
        Session_Block
        LFPFolder
        SpikeArrays
        Injections
    end
    
    methods
        function obj = FiguresUnit()
            %FIGURESUNIT Construct an instance of this class
            %   Detailed explanation goes here
            obj.UnitListFile='/home/mdalam/Downloads/Analysis_code/diba-ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/UnitList.txt';
            obj.Session_Block='/home/mdalam/Downloads/Analysis_code/diba-ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/Ses_Block.txt';
            sf=SpikeFactory.instance;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessions=obj.getSessionNos;
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
                end
                SpikeArrays(ises)=spikeArray;
                clear spikeArray
            end
            obj.SpikeArrays=SpikeArrays;
            obj.Injections=[1 2.5];
            obj.Parameters=obj.getParameters;
        end
        
        function plotFireRate(obj)
            ff=FigureFactory.instance('/home/mdalam/Downloads/Analysis_code/diba-ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/figures');
            sessions=obj.SpikeArrays;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessionsNos=obj.getSessionNos;
            for ises=1:numel(sessionsNos)
                sublist=list(list.SESSIONNO==sessionsNos(ises),:);
                inj=unique(sublist.INJECTION);
                ani=unique(sublist.ANIMAL);
                sessionsstr(ises)=inj; %#ok<AGROW>
                legendstr(ises)=strcat(ani,'__',inj); %#ok<AGROW>
            end
            try close(1); catch, end; f=figure(1);f.Position=[1,1,2560/2,1348];
            for ises=1:numel(sessions)
                sesno=sessionsNos(ises);
                blnames=obj.getBlock(sesno).getBlockNames;
%                 blint=4;blnames=blnames(blint);%ALL BLOCKS
                clear axp axh
                for ibl=1:numel(blnames)
                    aBlockBOC=obj.getBlockOfChannels(sesno,blnames{ibl});
                    if ~exist('axp','var')
                        subplot(numel(sessions),1,ises);
                        [axp,axh,ps]=aBlockBOC.plot([],[],1:2:14);hold on;
                    else
                        [axp,axh,ps]=aBlockBOC.plot(axp,axh,1:2:14);hold on;
                    end
                    bocs{ibl}=aBlockBOC;
                end
                axp.YScale='log';
                axp.YLim=[1e-4 1e2];
%                 xlim=[bocs{1}.getStartTime bocs{4}.getEndTime]; %ALL BLOCKS
                xlim=duration({'3:30','18:30'},'InputFormat','hh:mm')+bocs{1}.getDate; %ALL BLOCKS FIXED
%                 xlim=[bocs{1}.getStartTime bocs{1}.getEndTime];%INTERESTED BLOCKS
                axp.XLim=xlim;
                axh.XLim=xlim;
                sesnos=obj.getSessionNos;
                axes(axp);
                obj.addInjections(sesnos(ises));
                ylabel('Firing Rate (Hz)');
                title(legendstr{ises})
                legend(ps,{'q1','q2','q3','q4','q5','mua','int'});
            end
            ylabel('Fire Rate (Hz)');
%             ff.save(strcat('allblocks_',blnames{ibl}));%INTERESTED BLOCKS
            ff.save('allblocks');%ALL BLOCKS
%             ff.save('allblocksfixed');%ALL BLOCKS
        end
        function plotFireRateAroundInjection(obj)
            ff=FigureFactory.instance('/home/mdalam/Downloads/Analysis_code/diba-ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/figures'); 
            params=obj.getParameters;
            a=params.interestInMin.before;
            beforeInj1=minutes(a);
            a=params.interestInMin.after;
            afterInj1=minutes(a);
            sess=obj.getSessionNos;
            try close(2); catch, end; f=figure(2);f.Position=[1,1,2560/2,1348];
            for ises=1:numel(sess)
                sesno=sess(ises);
                sd=obj.getBlockOfChannels(sesno,'SD');
                its=obj.getInjectionTimes(sesno)+sd.getDate;
                for iinj=1:numel(its)
                    subplot(numel(sess),2,(ises-1)*2+iinj);
                    it=its(iinj);
                    bi=sd.getWindow(it+beforeInj1);
                    [axplot,axhyp]=bi.plot([],[],1:2:14);
                    ai=sd.getWindow(it+afterInj1);
                    [axplot,axhyp,ps]=ai.plot(axplot,axhyp,1:2:14);
                    axplot.YScale='log';
                    axplot.XLim=[bi.getStartTime ai.getEndTime];
                    axhyp.XLim=[bi.getStartTime ai.getEndTime];
                    axes(axplot);
                    obj.addInjections(sesno,iinj)
                    if ises==1
                        ylabel('Firing Rate (Hz)');
                        legend(ps,{'q1','q2','q3','q4','q5','mua','int'});
                    end
                end
            end
            ff.save('injection')
        end
    end
    methods (Access=private)
        function addInjections(obj,sesno,injnum)
            inj1=obj.getInjectionTimes(sesno);
            
            inj=obj.getBlockOfChannels(sesno,'SD').getDate+inj1;
            if exist('injnum','var')
                inj=inj(injnum);
            end
            for iline=1:numel(inj)
                l=xline(inj(iline));
                l.LineStyle='--';
                l.LineWidth=1.5;
                l.Color='r';
            end
        end
        function bl=getBlock(obj,ses)
            ses_block=readtable(obj.Session_Block,'Delimiter',',');     
            tbl=readtable(ses_block(ses_block.Session==ses,:).BlockFile{:});
            bl=SDBlocks(datetime(date),tbl);
        end
        function LFPFolder=getLFPFolder(obj,ses)
            ses_block=readtable(obj.Session_Block,'Delimiter',',');     
            filefolder=fileparts( ses_block(ses_block.Session==ses,:).BlockFile{:});
            f=split(filefolder,'/');
            LFPFolder=['/',fullfile(f{1:(end-1)})];
        end
        function boc=getBlockOfChannels(obj,sessionNo,blockName)
            sessionNos=obj.getSessionNos;
            sesidx=ismember(sessionNos,sessionNo);
            spikeArraysPerSession=obj.SpikeArrays;
            sa=spikeArraysPerSession(sesidx);
            sa_good=sa.getSub(ismember(sa.ClusterInfo.group,'good'));
            [fireRatem, fireRatee]=sa_good.getMeanFireRateQuintiles(5);
            bt=obj.getBlockTimes(sessionNo);
            nameidx=ismember(bt.BlockNames,blockName);
            blocktimes=bt.blockTimes';
            blocktime=blocktimes(nameidx,:);
            boc=BlockOfChannels();
            for iq=1:numel(fireRatem)
                frmq=fireRatem{iq};
                aBlockfrmq=frmq.getTimeWindow(blocktime);
                boc=boc.addChannel(aBlockfrmq);
                freq=fireRatee{iq};
                aBlockfreq=freq.getTimeWindow(blocktime);
                boc=boc.addChannel(aBlockfreq);
            end
            sa_mua=sa.getSub(ismember(sa.ClusterInfo.group,'mua'));
            [fireRatem, fireRatee]=sa_mua.getMeanFireRate();
            boc=boc.addChannel(fireRatem.getTimeWindow(blocktime));
            boc=boc.addChannel(fireRatee.getTimeWindow(blocktime));
            sa_undefined=sa.getSub(~ismember(sa.ClusterInfo.group,{'mua','good','unsorted'}));
            [fireRatem, fireRatee]=sa_undefined.getMeanFireRate();
            boc=boc.addChannel(fireRatem.getTimeWindow(blocktime));
            boc=boc.addChannel(fireRatee.getTimeWindow(blocktime));
            ss1=StateDetectionData(obj.getLFPFolder(sessionNo)).getStateSeries;
            ss=ss1.getWindow(blocktime);
            boc=boc.addHypnogram(ss);
        end
        function it=getInjectionTimes(obj,sesno)
            bt=obj.getBlockTimes(sesno);
            sdtime=bt.blockTimes(1,ismember(bt.BlockNames,'SD'));
            it=sdtime+hours(obj.Injections);
        end
        function params=getParameters(obj)
            params=readstruct('/home/mdalam/Downloads/Analysis_code/diba-ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/FigureUnit.xml');
        end
        function bl=getBlockTimes(obj,sesno)
            sessionInterests=[-hours(3) minutes(45) hours(4.5) hours(4)];
            block=obj.getBlock(sesno);
            sess=block.getBlockNames;
            for iblock=1:numel(sess)
                thebl=block.get(sess{iblock});
                dur=sessionInterests(iblock);
                if dur<0
                    thebl(1)=thebl(2)+dur;
                else
                    thebl(2)=thebl(1)+dur;
                end
                bl.blockTimes(:,iblock)=thebl; %#ok<AGROW>
            end
            bl.BlockNames=sess;
        end
        function ses=getSessionNos(obj)
            list=readtable(obj.UnitListFile,'Delimiter',',');
            ses=unique(list.SESSIONNO);
        end
    end
    
end

