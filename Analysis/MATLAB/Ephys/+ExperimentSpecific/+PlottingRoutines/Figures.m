classdef Figures
    %FIGURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    methods
        function obj = Figures()
            %FIGURES Construct an instance of this class
            %   Detailed explanation goes here
            
        end
    end 
    methods (Static)

        function plot_RippleRatesInBlocks_StatesSeparated(Conds)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            colorsall=linspecer(10,'sequential');
            colors=colorsall([10 8 1 5 3],:);
            conditions={'Control','Octopamine','Rolipram'};
            injections=[1, 2.5];
            for icond=1:numel(Conds)
                rcount=Conds(icond).rCount;
                scount=Conds(icond).sCount;
                scount(scount<seconds(minutes(2)))=nan;
                rrate=rcount./scount;
%                 sratio=Conds(icond).sratio;
                edges=hours(seconds(Conds(icond).edges(1,:,1)-1));
                centers=edges(2:end)-edges(2)/2;
                
                try close(icond);catch;end; f=figure(icond);f.Units='normalized';f.Position=[1.0000    0.4391    1.4    0.2];
                subplot(10,1,1:9);
                scountmean= minutes(seconds(nanmean(scount,3)));
                b=bar(centers, scountmean','stacked','BarWidth',1,'FaceAlpha',.3);
                ax=gca;
                ax.XTick=edges;
                ax.YLim=[0 30];
                ylabel('State Duration (min)');
                xlabel('Time (h)');
                hold on
                yyaxis right
                rratemean=nanmean(rrate,3);
                rrateErr=nanstd(rrate,[],3)/sqrt(size(rrate,3));
                centersall=repmat(centers,5,1);
                p=errorbar(centersall', rratemean',rrateErr','-','Marker','.','MarkerSize',20);
                centershift=([1 2 3 3 4]-4)*.05;
                for iplot=1:numel(p)
                    rrateSes=squeeze(rrate(iplot,:,:));
                    thecolor=colors(iplot,:);
                    plot(centers+centershift(iplot),rrateSes,'Color',thecolor,'LineWidth',.2,'Marker','.','MarkerSize',10,'LineStyle','none')
                    b(iplot).FaceColor=thecolor;
                    b(iplot).LineWidth=.2;
                    p(iplot).Color=thecolor;
                    p(iplot).LineWidth=2;
                end
                legend([b(1) b(2) b(3) b(5)],{'A-WAKE','Q-WAKE','SWS','REM'},'Location','bestoutside')
                title(conditions{icond});
                for iinj=1:numel(injections)
                    text(injections(iinj),-.1,'Injection','Rotation',45,'HorizontalAlignment','right');
                end
                ax=gca;
                ax.YColor='k';
                ax.YLim=[0 1.5];
                ax.XLim=[0 9.5];
                ylabel('SWR rate (#/s)');
                print(strcat('figures/RipleRate_',conditions{icond}),'-dpng','-r300')
            end
            
        end
        function plot_RippleRatesInBlocks_StatesCombined(Conds)
            colors=linspecer(3,'qualitative');
            conditions={'Control','Octopamin','Rolipram'};
            statesstr={'A-WAKE','Q-WAKE','SWS','REM'};
            injections=[1, 2.5];
            try close(4);catch;end; f=figure(4);f.Units='normalized';f.Position=[1.0000    0.4391    1.3806    0.4680];
            states=[1 2 3 5];
            for istate=1:numel(states)
                state=states(istate);
                subplot(numel(states),1,istate);hold on;
                for icond=1:numel(Conds)
                    rcount1=Conds(icond).rCount;
                    scount1=Conds(icond).sCount;
                    scount1(scount1<seconds(minutes(2)))=nan;
                    rrate=rcount1./scount1;
                    rratemean{icond}=nanmean(rrate,3);
                    rrateErr{icond}=nanstd(rrate,[],3)/sqrt(size(rrate,3));

                end
                edges=hours(seconds(Conds(1).edges(1,:,1)-1));
                centers=edges(2:end)-edges(2)/2;
                for icond=1:numel(Conds)
                    rratemeanstate=rratemean{icond};
                    rrateErrstate=rrateErr{icond};
                    p(icond)=errorbar(centers, rratemeanstate(state,:),rrateErrstate(state,:),'-','Marker','.','MarkerSize',20);
                    thecolor=colors(icond,:);
                    p(icond).Color=thecolor;
                    p(icond).LineWidth=2;
                end
                ax=gca;
                ax.XTick=edges;

                legend(p(:),conditions);
                title(statesstr{istate});
                for iinj=1:numel(injections)
                    text(injections(iinj),ax.YLim(1)-.1,'Injection','Rotation',45,'HorizontalAlignment','right');
                end
                ax=gca;
                ax.YColor='k';
%                 ax.YLim=[0 1];
                ax.XLim=[0 9.5];
                ylabel('SWR rate (#/s)');
            end
            set(gcf,'PaperPositionMode','manual');
            print(strcat('figures/RipleRateStates','-dpng','-r300','-bestfit', 'resize'));
        end
    end
end

