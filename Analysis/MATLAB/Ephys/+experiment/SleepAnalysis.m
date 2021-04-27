channels=[ 2 19 6 25 36 ]-1;
for ichan=1:1%numel(channels)
    channel=channels(ichan);
    ispre=1;
    if ispre
        basepath1{1}='/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day01_SD/merged_2019-Dec-22__04-01-10_18-45-27';
        basename1{1}=[basepath1{1} filesep 'merged_2019-Dec-22__04-01-10_18-45-27'];
        
        basepath1{2}='/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day02_NSD/merged_2019-Dec-23__05-00-08_18-27-11';
        basename1{2}=[basepath1{2} filesep 'merged_2019-Dec-23__05-00-08_18-27-11'];
        
        basepath1{3}='/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day03_SD/merged_2019-Dec-26__05-06-16_18-15-09';
        basename1{3}=[basepath1{1} filesep 'merged_2019-Dec-26__05-06-16_18-15-09'];
        
        basepath1{4}='/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day04_NSD/merged_2019-Dec-27__04-49-48_20-03-08';
        basename1{4}=[basepath1{4} filesep 'merged_2019-Dec-27__04-49-48_20-03-08'];
        
        
        
        
%         bz_getSessionInfo(basepath,'editGUI',true)
        % ignore_times=seconds([
        %     minutes(0)+seconds(195) seconds(220);
        %     minutes(540)+seconds(50) minutes(541)+seconds(40);
        %     minutes(572)+seconds(8) minutes(572)+seconds(20);
        %     ]);
%             channel=70;
%         
        SleepScoreMaster(basepath1{1},'SWChannels',channel,'ThetaChannels',channel,'overwrite',false);
%         SleepScoreMaster(basepath1{4},'SWChannels',channel,'ThetaChannels',channel,'overwrite',true);
%         
        
        close all
        clear times
        i=1;
        times{i}=[5 7 0;7 58 0];i=i+1;
        times{i}=[8 5 0;10 5 0];i=i+1;
        times{i}=[10 55 0;12 55 0];i=i+1;
        times{i}=[13 20 0;14 50 0];i=i+1;
        times{i}=[15 5 0;16 5 0];i=i+1;
        times{i}=[15 40 0;16 40 0];i=i+1;
        times{i}=[16 15 0;17 15 0];i=i+1;
        times{i}=[17 0 0;18 0 0];i=i+1;
%         clear powerSpecs
        for ibasepath=1:1
            sdd=StateDetectionData(basepath1{ibasepath});
            % probe=sdd.getProbe;
            % channels=probe.getShank(3).getSiteSpatialLayout.ChannelNumberComingOutPreAmp;
            % toks=tokenize( basepath1{1},filesep);
            % filebase=fullfile(filesep,toks{:},toks{end});
            % SWR=detect_swr(filebase,channels(1:3:end)-1,[],...
            %     'MAXGIGS',32,'minIsi',.02,'FIGS',true,'DEBUG',false,...
            %     'per_thresswD',5,'per_thresRip',25,...
            %     'thresSDswD',[.5 2.5],'thresSDrip',[.5 1.5],...
            %     'minDurRP',.01);
%             sdd.openStateEditor

            for itimes=1:numel(times)
                [powerSpecs(ibasepath,itimes) fnames{itimes}]= sdd.plot(channel,[duration(times{itimes}(1,1),...
                    times{itimes}(1,2),times{itimes}(1,3))...
                    duration(times{itimes}(2,1),times{itimes}(2,2),times{itimes}(2,3))],false);
                close
            end
        end
    end
    plotPowerSpectrums(powerSpecs,fnames,basepath1)
end

function plotPowerSpectrums(powerSpecs,fnames,basepath1)
colorl=linspecer(5);
statesmap=containers.Map([0 1 2 3 5],{'ALL','A-WAKE','Q-WAKE','SWS','REM'});
colors=containers.Map([0 1 2 3 5],{colorl(1,:),colorl(2,:),colorl(3,:),colorl(4,:),colorl(5,:)});

xlims={[1 20],[20 250]};
ylims={[33 58],[10 40]};
for ifocus=2:numel(xlims)
    focusno=ifocus;
    
    kwsignificance=5e-10;
    
    for itimes=1:size(powerSpecs,2)
        plotyaxis=[1,0,0,0,0];
        plotenlargehorizontally=[1,1,1,1,1]*1.1;
        plotlegend=[1,0,0,0,0];
        figure('Units','normalized','Position', [0 0 .5 .2],'Name',fnames{itimes})
        for isubplot=1:5
            ax(isubplot)=subplot(1,5,isubplot);
            ax(isubplot).Position(3)=ax(isubplot).Position(3)*plotenlargehorizontally(isubplot);
            if ~plotyaxis(isubplot)
                ax(isubplot).YLabel=[];
                ax(isubplot).YTickLabel=[];
            end
        end
        plotProportion=nan(size(powerSpecs,1),5);
        clear mat freq isSD p1 p2
        for ibasepath=1:size(powerSpecs,1)
            powerSpec=powerSpecs(ibasepath,itimes);
            iterator=powerSpec.PowerSpectrums.createIterator;
            iplot=0;
            while iterator.hasNext
                aPowerSpec=iterator.next;
                if aPowerSpec.InfoNum==5
                    num=5;
                else
                    num=aPowerSpec.InfoNum+1;
                end
                tfmap=aPowerSpec.TFMap
                [mat{ibasepath,num}, freq{ibasepath,num}]=tfmap.getSpectogramSamples
                axes(ax(num))
                p1=aPowerSpec.plot;
                hold on
                title(aPowerSpec.InfoName);
                try plotProportion(ibasepath,num)=aPowerSpec.SignalLenght;catch,end; iplot=iplot+1;
                tokens=tokenize(basepath1{ibasepath},filesep);
                isSD=tokenize(tokens{6},'_');
                isSDs{ibasepath,num}=isSD{2};
                plotLegends{ibasepath}=[tokens{5} '-' tokens{6}];
                if strcmpi(isSD{2},'SD')
                    colormult=.5;
                else
                    colormult=1;
                end
                p1.Color=colors(aPowerSpec.InfoNum)*colormult;
                p1.LineWidth=1;
                p2(ibasepath,num)=plot(freq{ibasepath},mean(pow2db(mat{ibasepath,num})));
                p2(ibasepath,num).Color=p1.Color;
                p2(ibasepath,num).LineWidth=2;
                ax(num).XLim=xlims{focusno};
                ax(num).YLim=ylims{focusno};

            end
            
        end
        for isubplot=1:5
            axes(ax(isubplot));
            try
                x=pow2db( mat{1,isubplot});
                y=pow2db(mat{2,isubplot});
                if ~isempty(x)&&~isempty(y)
                    z=vertcat(x,y);
                    group=ones(size(z,1),1);
                    group(1:size(x,1))=2;
                    freq1=freq{1};
                    for ifreq=1:size(z,2)
                        p(ifreq)=kruskalwallis(z(:,ifreq),group,'off');
                    end
                    average1=mean([mean(x);mean(y)]);
                    average1(p>kwsignificance)=nan;
                    pp=plot(freq1,average1,'.k');
                    pp.LineStyle='none';
                    pp.MarkerSize=10;
                    
                end
            catch
            end
            if plotlegend(isubplot)      
                legend([p2(1,1) p2(2,1)],plotLegends,'Interpreter','none')
            end
        end
        for isubplot=2:5
            ax1=axes;
            ax1.Position=ax(isubplot).Position;
            ax1.Position(1)=ax1.Position(1)+ax1.Position(3)+ax1.Position(3)/20;
            ax1.Position(3)=ax1.Position(3)/10;
            b1=bar(1,plotProportion(:,isubplot)*100,'stacked');
            for isession=1:numel(b1)
                try
                    if isubplot<5
                        coloridx=isubplot-1;
                    else
                        coloridx=isubplot;
                    end
                    if strcmpi(isSDs{isession,isubplot},'SD')
                        b1(isession).FaceColor=colors(coloridx)/2;
                    else
                        b1(isession).FaceColor=colors(coloridx);
                    end
                    %          b1(isession).EdgeColor=colors(isSDs{isession,isubplot});
                catch
                end
            end
            ax1.XLim=[0.9 1.1];
            ax(isubplot).YLabel=[];
        end
        f=FigureFactory.instance;
        f.save(sprintf('%s/%s-xlim%s.png',f.DefaultPath,fnames{itimes},num2str(xlims{focusno},'%03d-%03d') ))
        close
    end
end
end