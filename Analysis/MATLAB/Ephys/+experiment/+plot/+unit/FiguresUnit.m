classdef FiguresUnit
    %FIGURESUNIT Summary of this class goes here
    %   Detailed explanation goes here
    properties
        Parameters
        UnitListFile
        Session_Block
        LFPFolder
        SpikeArrays
    end
    
    methods
        function obj = FiguresUnit()
            logger=logging.Logger.getLogger;
             
            %FIGURESUNIT Construct an instance of this class
            %   Detailed explanation goes here
            obj.UnitListFile='./ExperimentSpecific/PlottingRoutines/UnitPlots/UnitList.csv';
            obj.Session_Block='./ExperimentSpecific/PlottingRoutines/UnitPlots/Ses_Block.csv';
            cachefolder='./ExperimentSpecific/PlottingRoutines/UnitPlots/cache';
            if ~isfolder(cachefolder), mkdir(cachefolder); end
            import neuro.spike.*
            sf=SpikeFactory.instance;
            list=readtable(obj.UnitListFile,'Delimiter',',');
            sessions=obj.getSessionNos;
            for ises=1:numel(sessions)
                ses=sessions(ises);
                cachefile=fullfile(cachefolder,strcat('unitarray_ses',num2str(ses)));
                try
                    load(cachefile,'spikeArray');
                    logger.info(['Session ' num2str(ses) 'loaded from cache.']);
                catch
                    rowidx=list.SESSIONNO==ses;
                    seslist=list(rowidx,:);
                    for is=1:height(seslist)
                        afolder=seslist(is,:);
                        sfFolder=afolder.PATH{:};
                        sa=sf.getPhyOutputFolder(sfFolder);
                        sa=sa.setShank(afolder.SHANKNO);
                        sa=sa.setLocation(string(afolder.LOCATION{1}));
                        logger.info(['Loaded Session ' num2str(ses) ...
                            ', Shank ' num2str(afolder.SHANKNO) '(' afolder.LOCATION{1} ')'])
                        try
                            spikeArray=spikeArray+sa;
                        catch
                            spikeArray=sa;
                        end
                    end
                    save(cachefile,'spikeArray');
                    logger.info(['Session ' num2str(ses) 'save to cache.']);
                end
                str=spikeArray.tostring('sh','location','group');
                logger.info(['Session ' num2str(ses) ' loaded from cache. ' strjoin(str,'; ')]);

                neuro.spike.SpikeArrays(ises)=spikeArray;
                clear spikeArray
            end
            obj.SpikeArrays=neuro.spike.SpikeArrays;
            obj.Parameters=obj.getParameters;
        end
        
    end
    
    methods (Access=protected)
        function bl=getBlock(obj,ses)
            ses_block=readtable(obj.Session_Block,'Delimiter',',');
            tbl=readtable(ses_block(ses_block.Session==ses,:).BlockFile{:});
            bl=experiment.SDBlocks(datetime(date),tbl);
        end
        function LFPFolder=getLFPFolder(obj,ses)
            ses_block=readtable(obj.Session_Block,'Delimiter',',');
            filefolder=fileparts( ses_block(ses_block.Session==ses,:).BlockFile{:});
            f=split(filefolder,'/');
            LFPFolder=['/',fullfile(f{1:(end-1)})];
        end
        function params=getParameters(obj)
            params=readstruct('./ExperimentSpecific/PlottingRoutines/UnitPlots/FigureUnit.xml');
        end
        function bl=getBlockTimes(obj,sesno,blockname)
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
            if exist('blockname','var')
                bl_idx=ismember(sess,blockname);
                if ~any(bl_idx)
                    if strcmp(blockname,'SD')
                        blockname='NSD';
                        bl_idx=ismember(sess,blockname);
                    end
                end
                bl=bl.blockTimes(:,bl_idx);
            end
        end
        function ses=getSessionNos(obj)
            list=readtable(obj.UnitListFile,'Delimiter',',');
            ses=unique(list.SESSIONNO);
        end
    end
    
end

