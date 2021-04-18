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
            obj.UnitListFile='/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/UnitList.txt';
            obj.Session_Block='/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/Ses_Block.txt';
            cachefolder='/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/cache';
            if ~isfolder(cachefolder), mkdir(cachefolder); end
            sf=SpikeFactory.instance;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessions=obj.getSessionNos;
            for ises=1:numel(sessions)
                ses=sessions(ises);
                cachefile=fullfile(cachefolder,strcat('unitarray_ses',num2str(ses)));
                try
                    load(cachefile,'spikeArray')
                catch
                    rowidx=list.SESSIONNO==ses;
                    seslist=list(rowidx,:);
                    for is=1:height(seslist)
                        afolder=seslist(is,:);
                        sfFolder=afolder.PATH{:};
                        sa=sf.getSpykingCircusOutputFolder(sfFolder);
                        sa=sa.setShank(afolder.SHANKNO);
                        try
                            spikeArray=spikeArray+sa;
                        catch
                            spikeArray=sa;
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
            figureFolder='/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/figures';
            if ~isfolder(figureFolder), mkdir(figureFolder);end
            ff=FigureFactory.instance(figureFolder);
            sessions=obj.SpikeArrays;
            fireratechannels=1:2:10;
%             fireratechannels=11:2:14;
            names={'q1','q2','q3','q4','q5'};
%             names={'mua','int'};
            smoothfactor=obj.getParameters.fireRatePlotSmoothingFactor;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessionsNos=obj.getSessionNos;
            for ises=1:numel(sessionsNos)
                sublist=list(list.SESSIONNO==sessionsNos(ises),:);
%                 inj=unique(sublist.INJECTION);
                ani=unique(sublist.ANIMAL);
%                 sessionsstr(ises)=inj; %#ok<AGROW>
                legendstr(ises)=strcat(ani,'__',unique(sublist.SLEEP)); %#ok<AGROW>
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
                        [axp,axh,ps]=aBlockBOC.plot([],[],fireratechannels,smoothfactor);hold on;
                        axes(axp);
                        grid on
                        aBlockBOC.plotStatewise(axp,axh,fireratechannels,smoothfactor);hold on;
                    else
                        [axp,axh,ps]=aBlockBOC.plot(axp,axh,fireratechannels,smoothfactor);hold on;
                        aBlockBOC.plotStatewise(axp,axh,fireratechannels,smoothfactor);hold on;
                    end
                    bocs{ibl}=aBlockBOC;
                end
                axp.YScale='log';
                axp.YLim=[1e-4 1e2];
                %                 xlim=[bocs{1}.getStartTime bocs{4}.getEndTime]; %ALL BLOCKS
                xlim=duration({'5:00','18:00'},'InputFormat','hh:mm')+bocs{1}.getDate; %ALL BLOCKS FIXED
                %                 xlim=[bocs{1}.getStartTime bocs{1}.getEndTime];%INTERESTED BLOCKS
                axp.XLim=xlim;
                axh.XLim=xlim;
                sesnos=obj.getSessionNos;
                axes(axp);
%                 obj.addInjections(sesnos(ises));
                ylabel('Firing Rate (Hz)');
                title(legendstr{ises})
                legend(ps,names);
            end
            ylabel('Fire Rate (Hz)');
            %             ff.save(strcat('allblocks_',blnames{ibl}));%INTERESTED BLOCKS
            ff.save('allblocksstatewise');%ALL BLOCKS
            %             ff.save('allblocksfixed');%ALL BLOCKS
        end
        function plotFireRateAroundInjection(obj)
            ff=FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/figures');
            params=obj.getParameters;
            smoothfactor=params.fireRatePlotSmoothingFactor;
            fireratechannels=1:2:10;
%             fireratechannels=11:2:14;
            names={'q1','q2','q3','q4','q5'};
%             names={'mua','int'};
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
                    [axplot,axhyp]=bi.plot([],[],fireratechannels,smoothfactor);
                    bi.plotStatewise(axplot,axhyp,fireratechannels,smoothfactor)
                    ai=sd.getWindow(it+afterInj1);
                    [axplot,axhyp,ps]=ai.plot(axplot,axhyp,fireratechannels,smoothfactor);
                    ai.plotStatewise(axplot,axhyp,fireratechannels,smoothfactor)
                    axplot.YScale='log';
                    axplot.XLim=[bi.getStartTime ai.getEndTime];
                    axhyp.XLim=[bi.getStartTime ai.getEndTime];
                    axes(axplot);
                    obj.addInjections(sesno,iinj)
                    if ises==1
                        ylabel('Firing Rate (Hz)');
                        legend(ps,names);
                    end
                end
            end
            ff.save('injection')
        end
        
        function plotFireRateStatewise(obj)
            ff=FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/figures');
            params=obj.getParameters;
            smoothfactor=params.fireRatePlotSmoothingFactor;
            sess=obj.getSessionNos;
            try close(3); catch, end; f=figure(3);f.Position=[1,1,2560/2,1348];
            for ises=1:numel(sess)
                sesno=sess(ises);
                sd=obj.getBlockOfChannels(sesno,'SD');
                sd.plotStatewise([],[],1:2:10,smoothfactor)
                AW=sd.getState1(1);
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
            bt=obj.getBlockTimes(sessionNo);
            nameidx=ismember(bt.BlockNames,blockName);
            blocktimes=bt.blockTimes';
            blocktime=blocktimes(nameidx,:);
            
            timebin=obj.getParameters.timeBinsForFireRateInSeconds;
            sessionNos=obj.getSessionNos;
            sesidx=ismember(sessionNos,sessionNo);
            spikeArraysPerSession=obj.SpikeArrays;
            sa=spikeArraysPerSession(sesidx);
            sa_good=sa.getSub(ismember(sa.ClusterInfo.group,'good'));
            frs=sa_good.getFireRates(10);
            
            blocktime_sd=blocktimes(3,:);%% run
            blocktime_all=[blocktimes(1,1) blocktimes(4,2)];%% all
            block=frs.getWindow(blocktime_all);
            [B,order]=sort(mean(block.Data,2));
            [fireRatem, fireRatee]=sa_good.getMeanFireRateQuintiles(5,timebin,order);
            boc=BlockOfChannels();
            for iq=1:numel(fireRatem)
                frmq=fireRatem{iq};
                try
                    aBlockfrmq=frmq.getTimeWindow(blocktime);
                catch
                end
                boc=boc.addChannel(aBlockfrmq);
                freq=fireRatee{iq};
                aBlockfreq=freq.getTimeWindow(blocktime);
                boc=boc.addChannel(aBlockfreq);
            end
            sa_mua=sa.getSub(ismember(sa.ClusterInfo.group,'mua'));
            [fireRatem, fireRatee]=sa_mua.getMeanFireRate(timebin);
            boc=boc.addChannel(fireRatem.getTimeWindow(blocktime));
            boc=boc.addChannel(fireRatee.getTimeWindow(blocktime));
%             sa_undefined=sa.getSub(~ismember(sa.ClusterInfo.group,{'mua','good','unsorted'}));
%             [fireRatem, fireRatee]=sa_undefined.getMeanFireRate(timebin);
%             boc=boc.addChannel(fireRatem.getTimeWindow(blocktime));
%             boc=boc.addChannel(fireRatee.getTimeWindow(blocktime));
            ss1=StateDetectionData(obj.getLFPFolder(sessionNo)).getStateSeries;
            ss=ss1.getWindow(blocktime);
            boc=boc.addHypnogram(ss);
            info.SessionNo=sessionNo;
            info.BlockName=blockName;
            boc=boc.setInfo(info);
        end
        function it=getInjectionTimes(obj,sesno)
            bt=obj.getBlockTimes(sesno);
            sdtime=bt.blockTimes(1,ismember(bt.BlockNames,'SD'));
            it=sdtime+hours(obj.Injections);
        end
        function params=getParameters(obj)
            params=readstruct('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/FigureUnit.xml');
        end
        function bl=getBlockTimes(obj,sesno)
            sessionInterests=[-hours(3) hours(5) hours(1.5) hours(3)];
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

