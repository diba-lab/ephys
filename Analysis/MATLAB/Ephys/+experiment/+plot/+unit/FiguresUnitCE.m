classdef FiguresUnitCE
    %FIGURESUNITCE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        CellMetricsSessions
        acgtbl
    end

    methods
        function obj = FiguresUnitCE()
            %FIGURESUNITCE Construct an instance of this class
            %   Detailed explanation goes here
            sesf=experiment.SessionFactory;
            sess=sesf.getSessions;
            ius=1;
            for ises=1:numel(sess)
                ses=sess(ises);
                us=buzcode.CellMetricsSession(char(ses.SessionInfo.baseFolder));
                if ~isempty(us.CellMetricsStruct)
                    cellMetricsWithSesions(ius)=us;
                    sessions(ius)=ses;ius=ius+1;
                end
            end
            obj.CellMetricsSessions=cellMetricsWithSesions;
            l=logging.Logger.getLogger;
            l.info(['All sessions with cell metrics calculated were loaded. ' ...
                '\n buzcode.CellMetrics(basepath)-->loadCellMetrics(''basepath\'',basepaths)'])
            l.info(obj.toString);
        end

        function str = toString(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            metSes=obj.CellMetricsSessions;
            str=[];
            for imet=1:numel(metSes)
                us=metSes(imet);
                str=strcat(str,sprintf('\n\n%s',us.toString));
            end
        end
        function tbl = getEV(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            try close(1);catch,end;f1=figure(1);f1.Position=[1 1 560 1350];
            try close(2);catch,end;f2=figure(2);f2.Position=[561 1 560 1350];
            fsd=1;fnsd=1;
            for ises=1:numel(obj.CellMetricsSessions)
                % try
                try close(2 + ises);catch,end
                fx=figure(2 + ises);fx.Position=[100 1 560*3 1350];
                ses=obj.CellMetricsSessions(ises);
                sa1=ses.getSpikeArray;
                dlfp=ses.Session.getDataLFP;
                sdd=dlfp.getStateDetectionData;
                tbl=sa1.ClusterInfo;
                aidx=~ismember(tbl.brainRegion,'CA3')&tbl.firingRateGiniCoeff<.5;
                sa2=sa1.get(aidx);
                bls=ses.Session.Blocks;
                blnames=bls.getBlockNames;
                window= [15 15 15 15]'*60;
                shift=  [5 5  5  5]'*60;
                tblbl=table(blnames,window,shift);
                try
                    if height(sa2.ClusterInfo)>10
                    fr2=sa2.getFireRates(.25);
                    subplot(4,1,1);
                    cb=fr2.plotFireRates;
                    sw=sdd.getSWLFP.getBandpassFiltered([.5 4]).getZScored+size(fr2.Data,1)/10;
                    p1=sw.plot;
                    for il=1:numel(p1)
                        p1(il).Color=[1 1 1]-.2;
                        p1(il).LineWidth=.3;
                    end
                    cb.Position(2)=.8;cb.Position(4)=.1;
                    axfr=gca;
                    axfr.CLim=[0 2];
                    axfr.XLim=[-4 12];
                    axfr.Color=[0 0 0];
                    axfr.YDir='normal';
                    ylabel('Unit #')
%                     pwc1=fr2.getPairwiseCorrelation(tblbl(1,:).window,tblbl(1,:).shift);
%                     idx=~isnan(pwc1.R);
                    nquint=5;
                    binformean=.25*60;
                    [frm,fre]=sa2.getMeanFireRateQuintiles(nquint,binformean);
                    t1=seconds(frm{1}.getTimeInterval.getTimePointsInSec)+frm{1}.getTimeInterval.getStartTime-frm{1}.getTimeInterval.getDate;
                    t=hours(t1-ses.Session.SessionInfo.ZeitgeberTime);
                    for iq=1:nquint
                        step=size(fr2.Data,1)/nquint;
%                         shadedErrorBar(t,normalize(frm{iq}.Values,'range')*step+step*(iq-1),fre{iq}.Values,'lineprops',{'w-'})
                        pf=plot(t,normalize(frm{iq}.Values,'range')*step+step*(iq-1),'Color',[1 1 1]-.6+iq/2/nquint);
                        pf.LineWidth=1;
                    end
                    mfr=sa2.getMeanFireRate(binformean);
                    p=plot(t,normalize(mfr.Values,'range')*size(fr2.Data,1),Color=[1 1 1],LineWidth=2);
                    %% in for create the table that holds PRE, SD, RUN, and POST
                    for ibl=1:numel(blnames)
                        blockname=blnames{ibl};
                        wind=bls.get(blockname);
                        %                     frm=sa.getMeanFireRate(.25);
                        fr=fr2.getWindow(wind);
                        pwc=fr.getPairwiseCorrelation(tblbl(ibl,:).window,tblbl(ibl,:).shift);
                        pwc.block(:,1)={blockname};
                        pwc.timeZT=pwc.time+seconds(wind(1)-ses.Session.SessionInfo.ZeitgeberTime);
                        if ibl==1
                            pwcall=pwc;
                        else
                            pwcall=[pwcall;pwc];
                        end
                        if ibl==3
                            window1=seconds(fr.Time.getEndTime-fr.Time.getStartTime);
                            pwc=fr.getPairwiseCorrelation(window1,window);
                            pwc.block(:,1)={[blockname 'b']};
                            pwc.timeZT=pwc.time+seconds(wind(1)-ses.Session.SessionInfo.ZeitgeberTime);
                            pwcall=[pwcall;pwc];
                        end
                    end
%                     pwcall=pwcall1(idx,:);
                    pwcall=obj.removeNAN(pwcall);
                    post=pwcall(ismember(pwcall.block,'POST'),:);
                    pre=pwcall(ismember(pwcall.block,'PRE'),:);
                    if strcmp(ses.Session.SessionInfo.Condition,'SD')
                        sd=pwcall(ismember(pwcall.block,'SD'),:);
                    else
                        sd=pwcall(ismember(pwcall.block,'NSD'),:);
                    end
                    maze=pwcall(ismember(pwcall.block,'TRACK'),:);
                    mazeb=pwcall(ismember(pwcall.block,'TRACKb'),:);

                    axpwc=subplot(4,1,2:4);hold on;
%                     obj.plotPWC(pwcall(~ismember(pwcall.block,'TRACKb'),:));
                    cb=colorbar(axpwc,'Location','manual');
                    cb.Position=[.94 .2 .01 .3];
                    cb.Label.String='R';
                    obj.plotPWC(axpwc,pre);
                    obj.plotPWC(axpwc,sd);
                    obj.plotPWC(axpwc,maze);
                    obj.plotPWC(axpwc,post);
                    axpw=gca;
                    axpw.CLim=[-.5 .5];
                    axpw.XLim=[-4 12];
                    axpw.Color=[1 1 1];
                    ylabel('Pair #');
                    ctrl=sd;
%                     ctrl=pre;
                    evtblses=obj.getEVtbl(post,mazeb,ctrl);
                    evtblses=[evtblses;obj.getEVtbl(sd,mazeb,ctrl)];
                    evtblses=[evtblses;obj.getEVtbl(maze,mazeb,ctrl)];
                    evtblses=[evtblses;obj.getEVtbl(pre,mazeb,ctrl)];

                    evtblses.sessionNo(:)=ises;
                    evtblses.sessionType(:)=ses.Session.SessionInfo.Condition;
                    bl=othercolor('Blues7',5);
                    rd=othercolor('OrRd7',5);

                    if strcmpi(evtblses(1,:).sessionType,'SD')
                        figure(1);
                        axs=subplot(5,1,fsd);fsd=fsd+1;
                        [p_ev, p_rev]=obj.plotEV(evtblses,rd);
                        legend([p_ev.mainLine p_rev.mainLine],{'SD-EV','SD-REV'},Location="northwest")
                        axes(axpwc);yyaxis("right");
                        [p_ev, p_rev]=obj.plotEV(evtblses,rd);
                        legend([p_ev.mainLine p_rev.mainLine],{'SD-EV','SD-REV'},Location="northwest")
                    else
                        figure(2);
                        axs=subplot(5,1,fnsd);fnsd=fnsd+1;
                        [p_ev, p_rev]=obj.plotEV(evtblses,bl);
                        legend([p_ev.mainLine p_rev.mainLine],{'NSD-EV','NSD-REV'},Location="northwest")
                        axes(axpwc);yyaxis("right");
                        [p_ev, p_rev]=obj.plotEV(evtblses,bl);
                        legend([p_ev.mainLine p_rev.mainLine],{'NSD-EV','NSD-REV'},Location="northwest")

                    end
                    ylabel('R');
%                     axfr=gca;
%                     axfr.XLim=[-4 12];
%                     axpw.addlistener('XLim','PostSet',@(src,evnt)disp('Color changed'));
%                     ax.YLim=[0 .3];
                    if ises==1
                        evtbl=evtblses;
                    else
                        evtbl=[evtbl;evtblses];
                    end
                    axes(axs);
                    yyaxis("right");
                    p=plot(t,normalize(mfr.Values,'range')*size(fr2.Data,1),Color=[1 1 1]*.4,LineWidth=2);
                    ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/figures');
                    ff.save(['ses' num2str(ises)]);
                    end
                catch
                end
            end
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/figures');
            figure(1);ff.save('sdpost')
            figure(2);ff.save('nsdpost')
        end
        function [cb]=plotPWC(obj,ax,pwc)
            [a,b,c]=unique(pwc(:,{'timeZT','block','timeNo'}));
            for i=1:height(a)
                if i==1
                    arr1=pwc(c==i,"R").R;
                else
                    arr1=[arr1 pwc(c==i,"R").R];
                end
            end
            t=hours(seconds(mean(a.timeZT,2)));
            imagesc(ax,t,1:size(arr1,1),arr1);
            xlabel('ZT (Hrs)')
            colormap(ax,flipud(othercolor('RdBu11',40)));
            ax.YLim=[0 size(arr1,1)];
        end
        function pwc=removeNAN(obj,pwc)
            [a,b,c]=unique(pwc(:,{'timeZT','block','timeNo'}));
            for i=1:height(a)
                if i==1
                    arr1=pwc(c==i,"R").R;
                else
                    arr1=[arr1 pwc(c==i,"R").R];
                end
            end
            idx=any(isnan(arr1),2);
            pwc=pwc(~ismember(pwc.pairNo,find(idx)),:);
        end
    end
    methods (Access=private)
        function evtblses=getEVtbl(obj,win,maze,pre)
            timeNo=unique(win.timeNo);
            for itime=1:numel(timeNo)
                timeNo1=timeNo(itime);
                win1=win(win.timeNo==timeNo1,:);
                rwin=win1.R;
                rmaze=maze.R;
                timeNoPre=unique(pre.timeNo);
                for itimepre=1:numel(timeNoPre)
                    pre1=pre(pre.timeNo==timeNoPre(itimepre),:);
                    rpre=pre1.R;
                    ev(itimepre,1)=obj.calcEV(rwin,rmaze,rpre);
                    rev(itimepre,1)=obj.calcREV(rwin,rmaze,rpre);
                end
                evtbl1=table(ev,rev);
                evtbl1.win(:)=itime;
                evtbl1.time(:)=mean(win1(1,:).time);
                evtbl1.timeZT(:)=mean(win1(1,:).timeZT);
                if itime==1
                    evtblses=evtbl1;
                else
                    evtblses=[evtblses;evtbl1];
                end
            end
            try
                evtblses.block(:)=win1.block(1);
            catch 
            end
        end
        function ev=calcEV(~,rwin,rmaze,rpre)
            rmaze_pre1=corrcoef([rpre rmaze],'Rows','pairwise');
            rmaze_pre=rmaze_pre1(1,2);
            rmaze_win1=corrcoef([rwin rmaze],'Rows','pairwise');
            rmaze_win=rmaze_win1(1,2);
            rwin_pre1=corrcoef([rwin rpre],'Rows','pairwise');
            rpre_win=rwin_pre1(1,2);
            ev=( ...
                (rmaze_win-rmaze_pre*rpre_win)/ ...
                (sqrt(1-rmaze_pre^2))*sqrt(1-rpre_win^2) ...
                )^2;
        end
        function rev=calcREV(~,rwin,rmaze,rpre)
            rmaze_pre1=corrcoef([rpre rmaze],'Rows','pairwise');
            rmaze_pre=rmaze_pre1(1,2);
            rmaze_win1=corrcoef([rwin rmaze],'Rows','pairwise');
            rmaze_win=rmaze_win1(1,2);
            rwin_pre1=corrcoef([rwin rpre],'Rows','pairwise');
            rpre_win=rwin_pre1(1,2);
            rev=( ...
                (rmaze_pre-rmaze_win*rpre_win)/ ...
                (sqrt(1-rmaze_pre^2))*sqrt(1-rpre_win^2) ...
                )^2;
        end
        function [p_ev, p_rev]=plotEV(~,tbl,colors)
            blocks=unique(tbl(:,{'block'}));
            for ibl=1:numel(blocks)
                tbl1=tbl(ismember(tbl.block,blocks(ibl,:).block),:);
                wins=unique(tbl1.win);
                clear t y_ev y_ev_se y_rev y_rev_se;
                for i=1:height(wins)
                    win1=tbl1(tbl1.win==wins(i),:);
                    y_ev(i)=mean(win1.ev);
                    y_ev_se(i)=std(win1.ev)/sqrt(numel(win1.ev));
                    y_rev(i)=mean(win1.rev);
                    y_rev_se(i)=std(win1.rev)/sqrt(numel(win1.rev));

                    t(i)=win1.timeZT(1);
                end

                p_ev=shadedErrorBar(hours(seconds(t)),y_ev,y_ev_se);
                p_ev.edge(1).Color=colors(3,:);
                p_ev.edge(2).Color=colors(3,:);
                p_ev.mainLine.Color=colors(5,:);
                p_ev.patch.FaceColor=colors(5,:);
                p_ev.mainLine.LineWidth=1.5;

                p_rev=shadedErrorBar(hours(seconds(t)),y_rev,y_rev_se);
                p_rev.edge(1).Color=colors(2,:);
                p_rev.edge(2).Color=colors(2,:);
                p_rev.mainLine.Color=colors(3,:);
                p_rev.patch.FaceColor=colors(3,:);
                p_rev.mainLine.LineWidth=1.5;
            end
        end

    end
    methods
        function obj=plotACG(obj)
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/UnitPlots/ACG/CA1');
            if ~isempty(obj.acgtbl)
                tbl1=obj.acgtbl;
            else
                tbl1=obj.getACG;
                obj.acgtbl=tbl1;
            end

            save=1;

            tbl2=experiment.plot.unit.figuresUnitCE.ACGFinalTable(obj.merge(tbl1));
            loc1=[2561 703 2560 634];
            loc2=[2561 210 2560 552];

            excludes={{'+,brainRegion,CA1','-,cellType,Wide Interneuron','-,synapticEffect,Unknown'},...
                {'+,brainRegion,CA1','-,cellType,Wide Interneuron'},...
                {'+,brainRegion,CA1,CA3'},...
                {'+,brainRegion,CA1','-,synapticEffect,Unknown'}}';
            groups={{'cellType','synapticEffect'},...
                {'cellType'},...
                {'brainRegion'},...
                {'synapticEffect'}}';
            t1=table(excludes,groups);

            for iplot=1:height(t1)
                try close(iplot*2-1); catch, end; f(1)=figure(iplot*2-1);
                f(1).Units='pixels';f(1).Position=loc1;
                try close(iplot*2); catch, end; f(2)=figure(iplot*2);
                f(2).Units='pixels';f(2).Position=loc2;
                ln1=t1(iplot,:);
                group=ln1.groups{:};sort1=group;exclude=[ln1.excludes{:} '+,group,good'];
                tbl2.plot(f,group,sort1,exclude)
                if save
                    figure(f(1));pause(1);ff.save(strcat(strjoin(group),'_image'));
                    figure(f(2));pause(1);ff.save(strcat(strjoin(group),'_violin'));
                end
            end

        end

        function blocks=merge(~,tbl)
            [blocks,~,b]=unique(tbl(:,{'condition','block','hour'}));
            for i=1:height(blocks)
                acgs=tbl(b==i,:).acg;
                for iacg=1:numel(acgs)
                    if iacg==1
                        acgall=acgs{iacg};
                    else
                        acgall=acgall+acgs{iacg};
                    end
                end
                blocks.acg{i}=acgall;
            end
        end
    end
end

