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
        function runningWindowTheta = getRunningWindows(obj,s_ratios,states_sub)
            runningWindowTheta=[];
            tblres=obj.Table;
            sf=experiment.SessionFactory; 
            sessions=unique(s_ratios.Session);
            for ises=1:numel(sessions)
                sesno=sessions(ises);
                tblres_ses=tblres(tblres.Session==sesno,:);
                ses=sf.getSessions(sesno);
                zt=ses.SessionInfo.ZeitgeberTime+ses.SessionInfo.Date;
                ztcenter=tblres_ses.AbsStart+(tblres_ses.AbsEnd-tblres_ses.AbsStart)/2-zt;
                idx_ses=s_ratios.Session==sesno;
                s_sub=s_ratios(idx_ses,:);
                peaktbl=[];
                for isub=1:height(s_sub)
                    win1=s_sub(isub,:);
                    win2=[win1.ZTStart win1.ZTEnd];
                    tblres_ses_win=tblres_ses(ztcenter>win2(1)&ztcenter<win2(2),:);
                    tblres_ses_win1=tblres_ses_win(ismember(tblres_ses_win.State,states_sub),:);
                    if height(tblres_ses_win1)>0
                        for ibout=1:height(tblres_ses_win1)
                            sig=tblres_ses_win1(ibout,:).Signal;
                            if ibout==1
                                sig_combined=sig;
                            else
                                sig_combined=sig_combined+sig;
                            end
                        end
                        if sig_combined.getLength>seconds(3)
                            p_welch=sig_combined.getPSpectrumWelch;
                            p_welch_fooof=p_welch.getFooof;
                            pk=p_welch_fooof.getPeak([5 10]);
                        else
                            pk.bw=nan;pk.cf=nan;pk.power=nan;
                        end
                    else
                        pk.bw=nan;pk.cf=nan;pk.power=nan;
                    end
                    peaktbl=[peaktbl; struct2table(pk)];
                end
                st=array2table(repmat(categorical(join(string(states_sub))),height(s_sub),1), ...
                    "VariableNames",{'States'});
                tbl_ses=[s_sub(:,{'Session','Condition','ZTStart','ZTCenter','ZTEnd'}) ...
                    peaktbl st];
                runningWindowTheta=[runningWindowTheta; tbl_ses];
            end
        end
    end
end