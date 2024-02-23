classdef ACGFinalTable
    %ACGFINALTABLE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        tbl
    end

    methods
        function obj = ACGFinalTable(tbl)
            %ACGFINALTABLE Construct an instance of this class
            %   Detailed explanation goes here
            obj.tbl = tbl;
        end

        function obj = plot(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isa(varargin{1},'matlab.ui.Figure')
                f=varargin{1};
                if nargin>2
                    varargin=varargin(2:end);
                end
            else
                try close(1); catch, end; f(1)=figure(1);
                f(1).Units='pixels';f(1).Position=[1441,1250,2558,400];
                try close(2); catch, end; f(2)=figure(2);
                f(2).Units='pixels';f(2).Position=[1441,1250,2558,400];
            end
            tbl=obj.tbl;
            [~,~,b]=unique(tbl(:,{'block','hour'}));
            order=[5 8 9 6 7 10 1 2 3 4];

            for it=1:numel(order)
                el=order(it);
                idx=b==el;
                acgs=tbl.acg(idx);
                figure(f(1));
                dat=[];tag=[];
                title1=strcat(tbl(idx,"block").block(1),' [',num2str(tbl(idx,"hour").hour(1,:)),']');
                clear tblres;
                for icond=1:numel(acgs)
                    subplot(2,numel(order),it+(icond-1)*numel(order));
                    acg1=acgs{icond};
                    if nargin>4
                        exclude=varargin{3};
                        for iex=1:numel(exclude)
                            exclude1=exclude{iex};
                            sp=split(exclude1,',');
                            switch sp{1}
                                case '+'
                                    idxe=~ismember(acg1.Info.(sp{2}),sp(3:end));
                                case '-'
                                    idxe=ismember(acg1.Info.(sp{2}),sp(3:end));
                            end
                            acg1.Count(idxe,:)=[];
                            acg1.Info(idxe,:)=[];
                        end
                    end
                    summary1=acg1.plot(varargin{1:2});
                    if icond==1,title(title1);end
                    cond=tbl(idx,"condition").condition(icond);
                    summary1.condition(:)=cond;
                    if it==1, ylabel(cond);end
                    if exist('tblres','var')
                        tblres=[tblres;summary1];
                    else
                        tblres=summary1;
                    end
                end
                figure(f(2));
                [names,~,g]=unique(tblres(:,varargin{1}));
                for its=1:height(names)
                    subplot(height(names),numel(order),it+(its-1)*numel(order));
                    tbls=tblres(g==its,:);
                    vs=violinplot(tbls.thetaFreq,tbls.condition);
                    try
                        v1=vs(1);
                        v1.ViolinColor=[0, 0.4470, 0.7410];
                    end
                    try
                        v2=vs(2);
                        v2.ViolinColor=[0.8500, 0.3250, 0.0980];
                    end
                    ax=gca;ax.YLim=[5 10];
                    ax.YGrid='on';
                    if it==1, ax.YLabel.String=strjoin(table2cell(names(its,varargin{1})));end
                    if its==1,title(title1);end
                end
            end

        end
    end
end

