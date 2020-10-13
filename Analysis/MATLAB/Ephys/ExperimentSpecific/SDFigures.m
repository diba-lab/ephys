classdef SDFigures <Singleton
    %FIGURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FileTable
        Times
        PowerSpecs
    end
    
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function obj = SDFigures()
            % Initialise your custom properties.
            obj.FileTable=readtable(...
                fullfile('/data/EphysAnalysis/Structure', 'LFPfiles.txt'),...
                'Delimiter',',');
            i=1;
            times{i}=[5 7 0;7 58 0];i=i+1;
            times{i}=[8 5 0;10 5 0];i=i+1;
            times{i}=[10 55 0;12 55 0];i=i+1;
            times{i}=[13 20 0;14 50 0];i=i+1;
            %             times{i}=[15 5 0;16 5 0];i=i+1;
            %             times{i}=[15 40 0;16 40 0];i=i+1;
            times{i}=[16 15 0;17 15 0];i=i+1;
            %             times{i}=[17 0 0;18 0 0];i=i+1;
            %             times{i}=[15 5 0;18 0 0];i=i+1;
            obj.Times=times;
            
            times=obj.Times;
            basefolder='/data/EphysAnalysis/SleepDeprivationData/';
            list=dir(fullfile(basefolder,'*.mat'));
            if numel(list)~=3
                for itime=timeNos
                    time=times{itime};
                    timestr{itime}=sprintf('%02d-%02d-%02d-%02d-%02d-%02d'...
                        ,time(1,1)...
                        ,time(1,2)...
                        ,(time(1,3))...
                        ,(time(2,1))...
                        ,(time(2,2))...
                        ,(time(2,3)));
                    files = obj.FileTable;
                    conds={'SD','NSD'};
                    for icond=1:numel(conds)
                        filegroup=files.Filepath(strcmp(files.Condition,conds{icond}));
                        for ifile=1:numel(filegroup)
                            file=filegroup{ifile};
                            list=dir([file filesep '*' timestr{itime} '*powerspec*']);
                            t=load(fullfile(list.folder,list.name));
                            fnames=fieldnames(t);
                            pwrspccombined=t.(fnames{1});
                            ps=pwrspccombined.PowerSpectrums;
                            for istate=1:ps.length
                                psstate=ps.get(istate);
                                tfmap=psstate.TFMap;
                                TFmatrix_ch{icond, itime, psstate.InfoNum+1,ifile}=pow2db(tfmap.matrix);
                                fpoints_ch=tfmap.frequencyPoints;
                                TFmatrix_bz{icond, itime, psstate.InfoNum+1,ifile}=psstate.Slope.specgram;
                                fpoints_bz=psstate.Slope.freqs;
                                TFmatrix_bzres{icond, itime, psstate.InfoNum+1,ifile}=psstate.Slope.resid;
                                fpoints_bzres=psstate.Slope.freqs;
                            end
                            
                        end
                        
                    end
                end
                tfmat=TFmatrix_ch;fpoints=fpoints_ch;
                save([basefolder 'pspecs_ch'],'tfmat','conds','timestr','fpoints','-v7.3')
                tfmat=TFmatrix_bz;fpoints=fpoints_bz;
                save([basefolder 'pspecs_bz'],'tfmat','conds','timestr','fpoints','-v7.3')
                tfmat=TFmatrix_bzres;fpoints=fpoints_bzres;
                save([basefolder 'pspecs_bzres'],'tfmat','conds','timestr','fpoints','-v7.3')
            end
            s=load(fullfile(basefolder,'pspecs_ch.mat'));
            obj.PowerSpecs=s;
        end
    end
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = SDFigures();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    methods
        
        
        function outputArg = runBasics(obj,fileNos,timeNos)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            LoadTimesFromFile=true;
            channel=1;
            files = obj.FileTable;
            for ifile=fileNos
                file=files.Filepath{ifile};
                sdd=StateDetectionData(file);
                if ~LoadTimesFromFile
                    times=obj.Times;
                else
                    load(fullfile(file,'TimesWindowsForPSpecComp'));
                end
                for itimes=timeNos
                    [powerSpecs(ifile,itimes) fnames{itimes}]= sdd.plot(channel,[duration(times{itimes}(1,1),...
                        times{itimes}(1,2),times{itimes}(1,3))...
                        duration(times{itimes}(2,1),times{itimes}(2,2),times{itimes}(2,3))],true);
                    close
                end
                
            end
        end
        function outputArg = plotSDvsNSD(obj,timeNos)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            try close('PS Compare');catch,end;f=figure('Name','PS Compare','Units','normalized','Position', [0 0 1 1]);
            s=obj.PowerSpecs;
            tfmap=s.tfmat;
            conds=s.conds;
            timestr=s.timestr;
            f=s.fpoints;
            clear s;
            stateNos=[1 2 3 4 6];
            color_ses(1,:,:)=flipud(othercolor('OrRd9',6));
            color_ses(2,:,:)=flipud(othercolor('Blues9',6));
            states={'ALL','A-WAKE','Q-WAKE','SWS','REM'};
            for itime=1:numel(timestr)
                for istate=1:5
                    ax=subplot(5,numel(timestr),(istate-1)*numel(timestr)+itime);hold on;
                    ax.Position=[ax.Position(1)...
                        ax.Position(2)...
                        ax.Position(3)*1.1...
                        ax.Position(4)*1.25];
                    stateNo=stateNos(istate);
                    thetfmap=squeeze(tfmap(:,itime,stateNo,:));
                    if itime==1&&istate==1
                        baseline=thetfmap;
                    end
                    for icond=1:numel(conds)
                        sessions=squeeze(thetfmap(icond,:));
                        bsessions=squeeze(baseline(icond,:));
                        for isession=1:numel(sessions)
                            session=sessions{isession};
                            session(session==-inf|session==inf)=nan;
                            bsession=bsessions{isession};
                            bsession(bsession==-inf|bsession==inf)=nan;
                            mses=mean(session,'omitnan');
                            bmses=mean(bsession,'omitnan');
                            if ~isnan(  mses)
                                try
                                    yyaxis left;
                                    p1l=semilogx(ax,f,(mses-bmses)./bmses,'Color',...
                                        color_ses(icond,isession,:),'LineStyle','-',...
                                        'LineWidth',1);
                                    plotsesl(isession,icond)=p1l;
                                    yyaxis right;
                                    p1r=semilogx(ax,f,mses,'Color',color_ses(icond,isession,:),...
                                        'LineStyle',':','LineWidth',1);
                                    p1r.LineStyle=':';
                                    plotsesr(isession,icond)=p1r;
                                catch
                                end
                            end
                        end
                    end
                    %                     ax.XLim=[20 250];
                    yyaxis left
                    ax.YLim=[-.25 .25];
                    
                    yyaxis right
                    ax.YLim=[10 50];
                    ax.XGrid='on';
                    ax.YGrid='on';
                    
                    if itime~=1
                        %                         ax.YTickLabel=[];
                    else
                        yyaxis left
                        ylabel(states{istate});
                    end
                    %                     if istate~=5
                    %                         ax.XTickLabel=[];
                    %                     else
                    xlabel(timestr{itime});
                    
                    %                     end
                    ax.XScale='log';
                    try
                        legend(plotsesl(:),'SD AG Day1','SD AG Day3','NSD AG Day2','NSD AG Day4','Location','best')
                    catch
                    end
                    clear plotsesl
                end
            end
            fs=FigureFactory.instance;
            fs.save('PowerSpecs')
        end
    end
end


