classdef ThetaPeaksContainer3
    %THETAPEAKSCONTAINER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ThetaPeaks
        Fooofs
        Parameters
    end    
    properties
        condlist
        statelist
        blocklist
    end
    
    methods
        function obj = ThetaPeaksContainer3(thpks,fooof,params)
            %THETAPEAKSCONTAINER Construct an instance of this class
            %   Detailed explanation goes here
            obj.ThetaPeaks = thpks;
            obj.Fooofs = fooof;
            obj.Parameters=params;
            conds=fieldnames(obj.ThetaPeaks);
            blocks=fieldnames(obj.ThetaPeaks.(conds{1}));
            states=fieldnames(obj.ThetaPeaks.(conds{1}).(blocks{1}));
            obj.condlist=categorical(conds);
            obj.statelist=categorical(states);
            obj.blocklist=categorical(blocks);
        end
        function plotPeakFreqDist(obj, blockstr)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout/fooof');

            cols=[6 10 10 3 6];
            cols=[6 10 2 6];

            conds=obj.condlist(:);
            states=obj.statelist(1);
            
            blockidx=ismember(obj.blocklist,blockstr);
%             if any(ismember(find(blockidx),[2 3]))
%                 blockidx=logical([0 1 1 0 0]);
%             end
%             blocks=obj.blocklist(blockidx);
            blocks=obj.blocklist(blockidx);
            col=unique(cols(blockidx));
%             sesnos{1}=[3 2 4:9];
%             sesnos{2}=[4 1:2 5:10];
            
            try close(10); catch, end
            for icond=1:numel(conds)
                cond=conds(icond);
                try close(double(cond)+6); catch, end; f=figure(double(cond)+6);f.Position=[1,55,1280/10*col,1267];
                %                     switch cond
                %                         case condlist(1)
                %                             if any(ismember( blocks,blocklist(2:3)))
                %                                 blocks=blocklist(2);
                %                             end
                %                         case condlist(2)
                %                             if any(ismember( blocks,blocklist(2:3)))
                %                                 blocks=blocklist(3);
                %                             end
                %                     end
                for iblock=1:numel(blocks)
                    block=blocks(iblock);
                    for istate=1:numel(states)
                        state=states(istate);
                        sess=fieldnames(obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)));
                        for isession=1:numel(sess)
                            ses=sess{isession};
                            try
                                thpks=obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)).(ses);
                                thpks.plotCF(numel(sess),isession,col);
                            catch
                            end
                            if exist('thpksm','var')
                                    thpksm=thpksm.merge(thpks);
                                else
                                    thpksm=thpks;
                                end
                                clear thpks
                        end
                    end
                end
                txt=sprintf('ThetaPeak_dist_%s_%s_%s_',cond,block,state);
                drawnow
                ff.save(txt)
                f=figure(10);f.Position=[2096,1844,1280/10*col,200];
                if exist('axs','var')
                    axs=thpksm.plotCF(axs);
                else
                    axs=thpksm.plotCF();
                end
                drawnow
                clear thpksm
            end
            txt=sprintf('ThetaPeak_dist_Comparison_%s_%s_',block,state);
            ff.save(txt);
        end
        function plotPowerDist(obj, blockstr)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout/fooof');
            cols=[6 10 10 3 6];        
            conds=obj.condlist(1:2);
            states=obj.statelist(1);
            
            blockidx=ismember(obj.blocklist,blockstr);
            if any(ismember(find(blockidx),[2 3]))
                blockidx=logical([0 1 1 0 0]);
            end
            blocks=obj.blocklist(blockidx);
            col=unique(cols(blockidx));
            sesnos{1}=[3 2 4:9];
            sesnos{2}=[4 1:2 5:10];

            sesnos{1}=[3 2 4:6 8:9];
            sesnos{2}=[4 1 5:7 9:10];

            try close(10); catch, end
            for icond=1:numel(conds)
                cond=conds(icond);
                try close(double(cond)+6); catch, end
                f=figure(double(cond)+6);f.Position=[1,55,1280/10*col,1267];
                for isession=1:numel(sesnos{icond})
                    sesnos1=sesnos{icond};
                    session=sesnos1(isession);
                    switch cond
                        case obj.condlist(1)
                            if any(ismember( blocks,obj.blocklist(2:3)))
                                blocks=obj.blocklist(2);
                            end
                        case obj.condlist(2)
                            if any(ismember( blocks,obj.blocklist(2:3)))
                                blocks=obj.blocklist(3);
                            end
                    end
                    for iblock=1:numel(blocks)
                        block=blocks(iblock);
                        for istate=1:numel(states)
                            state=states(istate);
                                try
                                    thpks=obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)).(['ses' num2str(session)]);
                                    thpks.plotPW(numel(sesnos1),isession,col);
                                catch
                                end
                                if exist('thpksm','var')
                                    thpksm=thpksm.merge(thpks);
                                else
                                    thpksm=thpks;
                                end
                                clear thpks
                        end
                    end
                end
                txt=sprintf('ThetaPower_dist_%s_%s_%s_',cond,block,state);
                drawnow
                ff.save(txt)
                f=figure(10);f.Position=[2096,1844,1280/10*col,200];
                if exist('axs','var')
                    axs=thpksm.plotPW(axs);
                else
                    axs=thpksm.plotPW();
                end
                drawnow
                clear thpksm
            end
            txt=sprintf('ThetaPower_dist_Comparison_%s_%s_',block,state);
            ff.save(txt);
        end
        function plotDurationvsFrequency(obj,blockstr)
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout/fooof');            
            durlim=[3 150];
            numsubs=[6 10 10 3 6];
            rotates=[10.5 6 6 25 10.5];

            conds=obj.condlist(1:2);
            states=obj.statelist(1);
            colorstr1={'Blues7','Oranges7'};
            colorstr2={'RdBu10','RdBu10'};
            blockidx=ismember(obj.blocklist,blockstr);
            if any(ismember(find(blockidx),[2 3]))
                blockidx=logical([0 1 1 0 0]);
            end
            blocks=obj.blocklist(blockidx);
            numsub=unique(numsubs(blockidx));
            rotate1=unique(rotates(blockidx));
            sesnos{1}=[3 2 4:9];
            sesnos{1}=1:9;
            sesnos{2}=[4 1:2 5:10];
            sesnos{2}=1:10;
            try close(7); catch, end
            try close(8); catch, end
            try close(9); catch, end
            try close(10); catch, end
            f=figure(9);f.Position=[1267/3,55,1280/5*numsub,1267];
            ax2(1)=subplot(2,1,1); ax2(2)=subplot(2,1,2);
            f=figure(10);f.Position=[1,55,1280/7*numsub,1267];
            ax1(1)=subplot(8,1,1:4);ax1(2)=subplot(2,2,3);
            f=figure(7);f.Position=[1267,55,1280/5*numsub,1267/3*2];
            f=figure(8);f.Position=[1267/2,55,1280/5*numsub,1267];
            axes(ax1(1));
            for icond=1:numel(conds)
                cond=conds(icond);
                colors=flipud(othercolor(colorstr1{icond},10));
                colors2=flipud(othercolor(colorstr2{icond},10));
%                 try close(double(cond)+6); catch, end;
                for isession=1:numel(sesnos{icond})
                    sesnos1=sesnos{icond};
                    session=sesnos1(isession);
                    switch cond
                        case obj.condlist(1)
                            if any(ismember( blocks,obj.blocklist(2:3)))
                                blocks=obj.blocklist(2);
                            end
                        case obj.condlist(2)
                            if any(ismember( blocks,obj.blocklist(2:3)))
                                blocks=obj.blocklist(3);
                            end
                    end
                    for iblock=1:numel(blocks)
                        block=blocks(iblock);
                        for istate=1:numel(states)
                            state=states(istate);
                            try
                                thpks=obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)).(['ses' num2str(session)]);
                                fooofs=obj.Fooofs.(char(cond)).(char(block)).(char(state)).(['ses' num2str(session)]);
                                thpks.Info.fooof=fooofs;
                                hold on
                                ax=gca;
                                %                             colors=linspecer(thpks.thpkList.length);

                                table1=thpks.plotDurationFrequency(gca,colors);
                                if exist('tableall','var')
                                    tableall=[tableall;table1];
                                else
                                    tableall=table1;
                                end
                            catch
                                l=logging.Logger.getLogger;
                                l.warning(sprintf('No content in %s %s %s %s',char(cond),char(block),char(state),['ses' num2str(session)]))
                            end
                        end
                    end
                end
            end
            tableall(isnan(tableall.Frequency)|tableall.Duration>durlim(2)|tableall.Duration<durlim(1),:)=[];
            ylim(durlim);
            zlim([5.5 8.5]);
            ylabel('Duration (s)');zlabel('Mean Instant Frequency');xlabel('Time-blocks (hrs)');
            %             view([45 145])
            xticks(1:numsub);
            xticklabels(.5:.5:numsub/2),grid on
            conds=unique(tableall.Condition);
            subblocks=unique(tableall.SubBlock);
            for icond=1:numel(conds)
                cond=conds(icond);
                colors=flipud(othercolor(colorstr1{icond},10));
                idx=tableall.Condition==icond;
                subtable=tableall(idx,:);
                axes(ax1(1));
                s1(icond)=scatter3(subtable.SubBlock,subtable.Duration,subtable.Frequency, ...
                    'filled',MarkerFaceColor=mean(colors),MarkerFaceAlpha=.5);
                for isub=1:numel(subblocks)
                    subblock=subblocks(isub);
                    idx=tableall.SubBlock==subblock&tableall.Condition==cond;
                    table1=tableall(idx,1:2);
                    [p,S,mu] = polyfit(table1.Duration,table1.Frequency,1);
                    [R,P] = corrcoef(table1.Duration,table1.Frequency);
                    if P(2,1)<.05
                        [f, delta ]= polyval(p,sort(table1.Duration),S,mu);
                        p1=plot3(ones(size(table1.Duration))*subblock,sort(table1.Duration),f,'-');
                        p2u=plot3(ones(size(table1.Duration))*subblock,sort(table1.Duration),f+2*delta,'-');
                        p2d=plot3(ones(size(table1.Duration))*subblock,sort(table1.Duration),f-2*delta,'-');
                        p1.Color=colors(1,:);p1.LineWidth=2.5;
                        p2u.Color=colors(1,:);p2u.LineWidth=2;p2u.LineStyle=':';
                        p2d.Color=colors(1,:);p2d.LineWidth=2;p2d.LineStyle=':';
                        t=text(subblock,mean(table1.Duration),mean(f), ...
                            sprintf('R=%.2f, p=%.3f',R(2,1),P(2,1)) ...
                            );
                        t.Color=mean(colors)/2;
                        rotate3d on
                    end
                end
                axes(ax1(2));hold on;
                tablecond=tableall(tableall.Condition==cond,:);
                s2(icond)=scatter(tablecond.Duration,tablecond.Frequency, ...
                    'filled',MarkerFaceColor=mean(colors),MarkerFaceAlpha=.2);
                xlim(durlim);
                ylim([5.5 8.5]);
                [p,S,mu] = polyfit(tablecond.Duration,tablecond.Frequency,1);
                [R,P] = corrcoef(tablecond.Duration,tablecond.Frequency);
                if P(2,1)<.05
                    [f, delta ]= polyval(p,sort(tablecond.Duration),S,mu);
                    p1=plot(sort(tablecond.Duration),f,'-');
                    p2u=plot(sort(tablecond.Duration),f+2*delta,'-');
                    p2d=plot(sort(tablecond.Duration),f-2*delta,'-');
                    p1.Color=colors(1,:);p1.LineWidth=2.5;
                    p2u.Color=colors(1,:);p2u.LineWidth=2;p2u.LineStyle=':';
                    p2d.Color=colors(1,:);p2d.LineWidth=2;p2d.LineStyle=':';
                    t=text(mean(tablecond.Duration),mean(f), ...
                        sprintf('R=%.2f, p=%.3f',R(2,1),P(2,1)) ...
                        );
                    t.Color=mean(colors)/2;
                end
                for isub=1:numsub
                    tablesub=tablecond(tablecond.SubBlock==isub,:);
                    numpoints=max(tablesub.Duration)*tablesub(1,:).Array.SampleRate;
                    [~,I]=sort(tablesub.Duration);
                    matp=nan(height(tablesub),numpoints);
                    matf=nan(height(tablesub),numpoints);
                    arrp1=[];
                    arrf1=[];
                    sig1=[];
                    for ibout=1:height(tablesub)
                        bout=tablesub(I(ibout),:);
                        boutarrp=bout.PowerArray;
                        boutarrp=boutarrp.getFillMissing(2).getLowpassFiltered(1);
                        matp(ibout,1:numel(boutarrp.Values))=boutarrp.Values;
                        arrp1=[arrp1 boutarrp.Values];
                        boutarrf=bout.Array;
                        boutarrf=boutarrf.getFillMissing(2).getLowpassFiltered(1);
                        matf(ibout,1:numel(boutarrf.Values))=boutarrf.Values;
                        arrf1=[arrf1 boutarrf.Values];
                        boutarrs=bout.Signal;
                        sig1=[sig1 boutarrs.Values];
                    end
                    figure(9)
                    ax=subplot(2,numsub,(icond-1)*numsub+isub);hold on;
                    imagesc(linspace(0,size(matf,2)/boutarrp.SampleRate,size(matf,2)),1:size(matf,1),matf)
                    colormap(ax,colors2);
                    ax=gca;
                    ax.CLim=[5.5 8.5];ax.XLim=[0 60];ax.YLim=[0 size(matf,1)];colorbar("northoutside")
                    drawnow;
                    figure(8)
                    ax=subplot(2,numsub,(icond-1)*numsub+isub);hold on;
                    imagesc(linspace(0,size(matp,2)/boutarrp.SampleRate,size(matp,2)),1:size(matp,1),matp)
                    colormap(ax,colors2);
                    ax=gca;
                    ax.CLim=[50 400];ax.XLim=[0 60];ax.YLim=[0 size(matp,1)];colorbar("northoutside")
                    figure(7)
                    try
                        axes(outset(isub));
                    catch
                        outset(isub)=subplot(1,numsub,isub);hold on;
                    end
                    idx=zscore(arrp1)<2|zscore(arrf1)<5;
                    arrf=arrf1(idx);
                    arrp=arrp1(idx);
                    s3(icond)=scatter(arrp,arrf, ...
                        'filled',MarkerFaceColor=mean(colors), ...
                        MarkerFaceAlpha=.05, ...
                        SizeData=.5 ...
                        );
                    xlim([0 600]);
                    ylim([5 10]);

                    [p,S,mu] = polyfit(arrp,arrf,1);
                    [R,P] = corrcoef(arrp,arrf);c=exp(-3*abs(R(2,1)));
                    if P(2,1)<.05
                        [f, delta ]= polyval(p,sort(arrp),S,mu);
                        p1=plot(sort(arrp),f,'-');
                        p2u=plot(sort(arrp),f+2*delta,'-');
                        p2d=plot(sort(arrp),f-2*delta,'-');
                        p1.Color=colors(ceil(c*10),:);p1.LineWidth=2.5;
                        p2u.Color=colors(ceil(c*10),:);p2u.LineWidth=2;p2u.LineStyle=':';
                        p2d.Color=colors(ceil(c*10),:);p2d.LineWidth=2;p2d.LineStyle=':';
                        t=text(mean(arrp),mean(arrf), ...
                            sprintf('R=%.2f, p=%.3f',R(2,1),P(2,1)) ...
                            );
                        t.Color=mean(colors)/2;
                    end
                    try
                        axes(inset(isub));
                    catch
                        ax=outset(isub);
                        inset(isub)=axes('Position', [ ...
                            ax.Position(1)+ax.Position(3)/3 ...
                            ax.Position(2)+ax.Position(4)*2/3 ...
                            ax.Position(3)/3*2 ...
                            ax.Position(4)/3] ...
                            );
                        hold on; box on;
                    end
                    sigosc=neuro.basic.Oscillation(sig1, boutarrs.SampleRate);
                    ps=sigosc.getPSpectrumWelch;
                    sett.aperiodic_mode='knee';
                    fooof2=ps.getFooof(sett);
                    [pi,model,ap_fit]=fooof2.plot;
                    pi.Color=colors(1,:);
                    pi.LineWidth=1;
                    model.LineStyle='none';
                    ap_fit.Color=colors(1,:);
                    ap_fit.LineWidth=1.5;
                    inset(isub).XScale='log';
                    inset(isub).YLim=[1 6];
                    inset(isub).Color='none';
                    box off;
                    legend off;
                end
            end
            axes(ax1(1))
            view(rotate1,0);
            legend(s1,{'NSD','SD'},Location="best")
            title(blockstr);


            
            subplot(3,2,6);hold on;
            h1=histogram(tableall.Duration(tableall.Condition==1),linspace(durlim(1),durlim(2),100),LineStyle="none", ...
                FaceColor=mean(othercolor(colorstr1{1},numsub*2)),Normalization="cdf",FaceAlpha=.3);
            plot(linspace(h1.BinEdges(1),h1.BinEdges(end),numel(h1.Values)), ...
                h1.Values,LineWidth=3,Color=h1.FaceColor);
            h2=histogram(tableall.Duration(tableall.Condition==2),linspace(durlim(1),durlim(2),100),LineStyle="none", ...
                FaceColor=mean(othercolor(colorstr1{2},numsub*2)),Normalization="cdf",FaceAlpha=.3);
            plot(linspace(h2.BinEdges(1),h2.BinEdges(end),numel(h2.Values)), ...
                h2.Values,LineWidth=3,Color=h2.FaceColor);
            xlim(durlim);
            ylim([0 1]);
            xlabel('Duration (s)');

            ff.save(sprintf('DurationVsFrequency_%s.png',blockstr))
            figure(9);
            ff.save(sprintf('DurationVsFrequency_raw%s.png',blockstr))
            figure(8);
            ff.save(sprintf('DurationVsPower_raw%s.png',blockstr))
            figure(7);
            ff.save(sprintf('PowerVsFrequency_raw%s.png',blockstr))

        end
    end

end

