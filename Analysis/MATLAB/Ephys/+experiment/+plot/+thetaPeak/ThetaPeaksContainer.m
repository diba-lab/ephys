classdef ThetaPeaksContainer
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
        function obj = ThetaPeaksContainer(thpks,fooof,params)
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
            clear ff;
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout/fooof');

            cols=[6 10 3 6];

            conds=obj.condlist;
            states=obj.statelist(1);
            if any(ismember({'SD','NSD'},blockstr))
                if numel(obj.blocklist)==4
                    blockidx=[false; true; false; false];
                else
                    blockidx=true;
                end
            else
                blockidx=ismember(obj.blocklist,blockstr);
            end
            block=obj.blocklist(blockidx);
            col=unique(cols(blockidx));


            try close(10); catch, end
            for icond=1:numel(conds)
                cond=conds(icond);
                try close(double(cond)+6); catch, end; f=figure(double(cond)+6);f.Position=[1,55,1280/10*col,1267];
                if any(ismember({'SD','NSD'},block))
                    block=cond;
                end
                for iblock=1:numel(block)
                    block=block(iblock);
                    for istate=1:numel(states)
                        state=states(istate);
                        fnames=fieldnames(obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)));
                        for isession=1:numel(fnames)
                            sesno=fnames{isession};
                            thpks=obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)).(sesno);
                            thpks.plotCF(numel(fnames),isession,col);
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
                thpksms(icond)=thpksm;
                clear thpksm
            end
            cmp=thpksms(1).compare(thpksms(2));
            for ip=1:numel(axs)
                text(axs(ip),min(axs(ip).XLim),max(axs(ip).YLim),...
                    sprintf('ks-test:%.3f', cmp(ip).CF.ks2stat),...
                    'HorizontalAlignment','right',VerticalAlignment='bottom',...
                    FontSize=8)
            end
            txt=sprintf('ThetaPeak_dist_Comparison_%s_%s_',block,state);
            ff.save(txt);
        end
        function plotSpeed(obj, blockstr)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            clear ff;
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout/fooof');

            cols=[6 10 3 6];

            conds=flipud(obj.condlist);
            states=obj.statelist(1 );
            if any(ismember({'SD','NSD'},blockstr))
                if numel(obj.blocklist)==4
                    blockidx=[false; true; false; false];
                else
                    blockidx=true;
                end
            else
                blockidx=ismember(obj.blocklist,blockstr);
            end
            block=obj.blocklist(blockidx);
            col=unique(cols(blockidx));


            try close(10); catch, end
            for icond=1:numel(conds)
                cond=conds(icond);
                try close(double(cond)+6); catch, end; f=figure(double(cond)+6);f.Position=[1,55,1280/10*col,1267];
                if any(ismember({'SD','NSD'},block))
                    block=cond;
                end
                for iblock=1:numel(block)
                    block=block(iblock);
                    for istate=1:numel(states)
                        state=states(istate);
                        fnames=fieldnames(obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)));
                        for isession=1:numel(fnames)
                            sesno=fnames{isession};
                            try
                                thpks=obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)).(sesno);
                                thpks.plotSpeed(numel(fnames),isession,col);
                                if exist('thpksm','var')
                                    thpksm=thpksm.merge(thpks);
                                else
                                    thpksm=thpks;
                                end
                            catch
                            end
                            clear thpks
                        end
                    end
                end
                txt=sprintf('Speed_dist_%s_%s_%s_',cond,block,state);
                drawnow
                ff.save(txt)
                f=figure(10);f.Position=[2096,1844,1280/10*col,200];
                if exist('axs','var')
                    axs=thpksm.plotSpeed(axs);
                else
                    axs=thpksm.plotSpeed();
                end
                drawnow
                clear thpksm
            end
            txt=sprintf('Speed_dist_Comparison_%s_%s_',block,state);
            ff.save(txt);
        end
        function plotPowerDist(obj, blockstr)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout/fooof');
            cols=[6 10 3 6];

            conds=obj.condlist;
            states=obj.statelist(1);
            if any(ismember({'SD','NSD'},blockstr))
                if numel(obj.blocklist)==4
                    blockidx=[false; true; false; false];
                else
                    blockidx=true;
                end
            else
                blockidx=ismember(obj.blocklist,blockstr);
            end
            block=obj.blocklist(blockidx);
            col=unique(cols(blockidx));


            try close(10); catch, end
            for icond=1:numel(conds)
                cond=conds(icond);
                try close(double(cond)+6); catch, end; f=figure(double(cond)+6);f.Position=[1,55,1280/10*col,1267];
                if any(ismember({'SD','NSD'},block))
                    block=cond;
                end
                for iblock=1:numel(block)
                    block=block(iblock);
                    for istate=1:numel(states)
                        state=states(istate);
                        fnames=fieldnames(obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)));
                        for isession=1:numel(fnames)
                            sesno=fnames{isession};
                            thpks=obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)).(sesno);
                            thpks.plotPW(numel(fnames),isession,col);

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
                thpksms(icond)=thpksm;
                clear thpksm
            end
            cmp=thpksms(1).compare(thpksms(2));
            for ip=1:numel(axs)
                text(axs(ip),min(axs(ip).XLim),max(axs(ip).YLim),...
                    sprintf('ks-test:%.3f', cmp(ip).Power.ks2stat),...
                    'HorizontalAlignment','right',VerticalAlignment='bottom',...
                    FontSize=8)
            end
            txt=sprintf('ThetaPower_dist_Comparison_%s_%s_',block,state);
            ff.save(txt);
        end
        function plotDurationvsFrequency(obj,blockstr)
            ff=logistics.FigureFactory.instance('/data/EphysAnalysis/Structure/diba-lab_ephys/Analysis/MATLAB/Ephys/ExperimentSpecific/PlottingRoutines/Printout/fooof');            
            durlim=[3 150];
            numsubs=[6 10 3 6];
            rotates=[10.5 6 25 10.5];

            conds=obj.condlist(:);
            states=obj.statelist(1);
            colorstr1={'Blues7','Oranges7'};
            colorstr2={'RdBu10','RdBu10'};
            if any(ismember({'SD','NSD'},blockstr))
                if numel(obj.blocklist)==4
                    blockidx=[false; true; false; false];
                else
                    blockidx=true;
                end
            else
                blockidx=ismember(obj.blocklist,blockstr);
            end
            block=obj.blocklist(blockidx);
            numsub=unique(numsubs(blockidx));
            rotate1=unique(rotates(blockidx));

            try close(7); catch, end
            try close(8); catch, end
            try close(9); catch, end
            try close(10); catch, end
            try close(11); catch, end
            f=figure(9);f.Position=[1267/3,55,1280/5*numsub,1267];
            ax2(1)=subplot(2,1,1); ax2(2)=subplot(2,1,2);
            f=figure(10);f.Position=[1,55,1280/7*numsub,1267];
            ax1(1)=subplot(8,1,1:4);ax1(2)=subplot(2,2,3);
            f=figure(7);f.Position=[1267,55,1280/5*numsub,1267/3*2];
            f=figure(11);f.Position=[1267,55,1280/5*numsub,1267/3*2];
            f=figure(8);f.Position=[1267/2,55,1280/5*numsub,1267];
            axes(ax1(1));
            for icond=numel(conds):-1:1
                cond=conds(icond);
                colors=flipud(othercolor(colorstr1{icond},10));
                colors2=flipud(othercolor(colorstr2{icond},10));
                if any(ismember({'SD','NSD'},block))
                    block=cond;
                end
                for iblock=1:numel(block)
                    block=block(iblock);
                    for istate=1:numel(states)
                        state=states(istate);
                        fnames=fieldnames(obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)));
                        for isession=1:numel(fnames)
                            sesno=fnames{isession};
                            thpks=obj.ThetaPeaks.(char(cond)).(char(block)).(char(state)).(sesno);
                            fooofs=obj.Fooofs.(char(cond)).(char(block)).(char(state)).(sesno);
                            thpks.Info.fooof=fooofs;
                            hold on
                            try
                                table1=thpks.plotDurationFrequency(gca,colors);
                                if exist('tableall','var')
                                    tableall=[tableall;table1];
                                else
                                    tableall=table1;
                                end
                            catch
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
                    if ~isempty(tablesub)
                        numpoints=round(max(tablesub.Duration)*tablesub(1,:).Array.SampleRate);
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
                            axo=outset(isub);
                            axn=axes;
                            axn.Position=axo.Position;
                        catch
                            outset(isub)=subplot(1,numsub,isub);hold on;
                            axn=gca;
                            axn.Color='none';
                        end
                        idx=zscore(arrp1)<2|zscore(arrf1)<5;
                        arrf=arrf1(idx);
                        arrp=arrp1(idx);
%                         s3(icond)=scatter(arrp,arrf, ...
%                             'filled',MarkerFaceColor=mean(colors), ...
%                             MarkerFaceAlpha=.2, ...
%                             SizeData=.5 ...
%                             );
%                         s3(icond)=dscatter(arrp',arrf','plottype','scatter');
                        s3(icond)=dscatter(arrp',arrf','plottype','contour');
                        colormap(s3(icond),othercolor(colorstr1{icond},7))
                        xlim([0 400]);
                        ylim([5 10]);

                        if icond>1          
                            axes(outset(isub));
                            axn.Visible='off';
                        end
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
                        figure(11)
                        try
                            axes(outset1(isub));
                        catch
                            outset1(isub)=subplot(1,numsub,isub);hold on;
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
                        outset1(isub).XScale='log';
                        outset1(isub).YLim=[1 6];
                        outset1(isub).Color='none';
                        box off;
                        legend off;
                    end
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

            ff.save(sprintf('DurationVsFrequency_%s_%s.png',blockstr,states))
            figure(9);
            ff.save(sprintf('DurationVsFrequency_raw%s_%s.png',blockstr,states))
            figure(8);
            ff.save(sprintf('DurationVsPower_raw%s_%s.png',blockstr,states))
            figure(7);
            ff.save(sprintf('PowerVsFrequency_raw%s_%s.png',blockstr,states))
            figure(11);
            ff.save(sprintf('Power_Spectrum%s_%s.png',blockstr,states))

        end
    end

end

