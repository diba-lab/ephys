classdef CellMetricsSession < buzcode.CellMetrics
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Session
    end
    
    methods
        function obj = CellMetricsSession(basepath)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj=obj@buzcode.CellMetrics(basepath)
            obj.Session=experiment.Session(basepath);
        end

        function obj = loadCellMetricsForBlock(obj,blockName)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.CellMetricsStruct=loadCellMetrics('basepath',obj.CellMetricsStruct.general.basepath, ...
                'saveAs',['cell_metrics_' blockName] ...
                );
        end

        function [H] = plotFR(obj,ax,groups)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if exist("ax","var")&&~isempty(ax)
                axes(ax);
            else
                ax=gca;
            end
            timebins=seconds(minutes(5));
            hold on;
%             ax.YScale='log';
            ses=obj.Session;
            
            bl=ses.getBlock;

            st=ses.getDataLFP.TimeIntervalCombined.getStartTime;
            zt=ses.getZeitgeberTime;
            bl.getZeitgeberTimes(zt).plot
            blnames=bl.getBlockNames;
            for igr=1:numel(groups)
                cm=obj.CellMetricsStruct;
                gr=groups{igr};
                fns=fieldnames(gr);
                idxgr=true([1 cm.general.cellCount]);
                for ifn=1:numel(fns)
                    fn=fns{ifn};
                    try
                        all1=cm.(fn);
                        sub1=gr.(fn);
                        if iscell(sub1)
                            idxsub=ismember(all1,sub1);
                            idxgr=idxgr&idxsub;
                        else
                            idxsub=(all1>=sub1(1)&all1<=sub1(2))|isnan(all1);
                            idxgr=idxgr&idxsub;
                        end
                    catch
                    end
                end
                
                for ib=1:numel(blnames)
                    block=blnames{ib};
                    wind=bl.get(block)+bl.getDate;
                    bendt=seconds(wind(2)-zt);
                    bstartt=seconds(wind(1)-zt);
                    edges=bstartt:timebins:bendt;
                    times=cm.spikes.times(idxgr);
                    clear fr
                    for iunit=1:numel(times)

                        fr(iunit,:)=histcounts(times{iunit}-seconds(zt-st),edges);

                    end
                    try
                        fr=zscore(fr/timebins,[],2);
%                         fr=fr/timebins;

                        edges=hours(seconds(edges));
                        t=edges(1:(end-1))+diff(edges);
                        %                 p1=plot(t,fr,Color=[.9 .9 .9],Marker=".");
                        H(igr)=shadedErrorBar(t,fr,{@mean,@(x) std(x)/sqrt(size(fr,1))});
                        H(igr).mainLine.Color=gr.color;
                        H(igr).patch.FaceColor=gr.color;
                        H(igr).edge(1).Color=gr.color+(1-gr.color)/2;
                        H(igr).edge(2).Color=gr.color+(1-gr.color)/2;
                    catch
                    end

                end

            end
        end
        function filter=getFilter(obj)
            cm=obj.CellMetricsStruct;
            fns=fieldnames(cm);
            for ifn=1:numel(fns)
                fn=fns{ifn};
                if iscell(cm.(fn))
                    filter.(fn)=unique(cm.(fn));
                elseif isnumeric(cm.(fn))
                    filter.(fn)=[min(cm.(fn)) max(cm.(fn))];
                else
                end
            end
        end
    end
end

