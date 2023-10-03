classdef StateTable

    properties
        Table
    end

    methods
        function obj = StateTable(table)
            obj.Table = table;
        end

        function obj = getDurationLongerThan(obj,dur)
            durs=obj.Table.AbsEnd - obj.Table.AbsStart;
            idx=durs>dur;
            obj.Table(~idx,:)=[];
        end
        function tbl_theta_peak = getFooofEstimatedTable(obj)
            tbl_theta_peak=[];
            for ibout=1:height(obj.Table)
                bout=obj.Table(ibout,:);
                signal1=bout.Signal;
                try
                    ps=signal1.getPSpectrumWelch;
                    fooof1=ps.getFooof;
                    pk=fooof1.getPeak([5 10]);
                    bout1=bout(:,{'AbsStart','AbsEnd','Block','Condition',...
                        'State','Session'});
                    bout=[bout1 struct2table(pk)];
                    tbl_theta_peak=[tbl_theta_peak; bout];
                catch ME

                end
            end
            % add ZT times
            sf=experiment.SessionFactory;
            sess=sf.getSessions;
            zts=datetime.empty(0,1);
            for ibout=1:height(tbl_theta_peak)
                bout=tbl_theta_peak(ibout,:);
                ses=sess(bout.Session);
                zts(ibout,1)=ses.SessionInfo.Date+ses.SessionInfo.ZeitgeberTime;
            end
            ztstart=tbl_theta_peak.AbsStart-zts;
            ztend=tbl_theta_peak.AbsEnd-zts;
            tbl_theta_peak=[tbl_theta_peak array2table(zts,...
                VariableNames={'ZT'})];
            tbl_theta_peak=[tbl_theta_peak array2table(ztstart,...
                VariableNames={'ZTstart'})];
            tbl_theta_peak=[tbl_theta_peak array2table(ztend,...
                VariableNames={'ZTend'})];
        end
    end
end