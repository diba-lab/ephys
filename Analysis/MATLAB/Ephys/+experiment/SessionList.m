classdef SessionList

    properties
        List
    end

    methods
        function obj = SessionList(sessions,sesnos)
            if size(sessions, 1) < size(sessions, 2)
                sessions = sessions';
            end
            if size(sesnos, 1) < size(sesnos, 2)
                sesnos = sesnos';
            end
            obj.List=[array2table(sesnos,VariableNames="SessionNo") ...
                array2table(sessions,VariableNames="Session") ];
        end

        function stateratios = getStateRatioTable(obj,blockcat)
            stateratios=[];
            for ises=1:numel(obj.List)
                ses=obj.List(ises,:).Session;
                % zt=ses.SessionInfo.ZeitgeberTime+ses.SessionInfo.Date;
                block=ses.getBlockZT(blockcat);
                lfp=ses.getDataLFP;
                sdd=lfp.getStateDetectionData;
                ss=sdd.getStateSeries;
                ss1=ss.getWindow(block+ss.TimeIntervalCombined.getZeitgeberTime);
                rats=ss1.getStateRatios(minutes(15),minutes(1.5),block);
                a=array2table(repmat(ises,height(rats),1),VariableNames={'SessionIdx'});
                b=array2table(repmat(obj.List(ises,:).SessionNo,height(rats),1), ...
                    VariableNames={'Session'});
                c=array2table(repmat(categorical(string(ses.SessionInfo.Condition)),height(rats),1), ...
                    VariableNames={'Condition'});
                subres=[a b c rats];
                stateratios=[stateratios;subres];
            end
        end
        function [] = saveRippleEventPropertiesTable(obj)
            for ises=1:height(obj.List)
                ses1=obj.List(ises,:);
                sesno=ses1.SessionNo;
                frippleEventSignalTable=sprintf(...
                    "Scripts/Theta/matfiles-rip/rippleEventSignalTable-ses%d.mat"...
                    ,sesno);
                frippleEventPropertiesTable=sprintf(...
                    "Scripts/Theta/matfiles-rip/rippleEvent_Properties_Table-ses%d.mat"...
                    ,sesno);
                if ~isfile(frippleEventSignalTable)
                    ses=experiment.SessionRipple(ses1.Session);
                    rippleChannels=ses.getRippleChannels;
                    rippleEventSignalTable1=[];
                    for irippchan=1:numel(rippleChannels)
                        rip1=rippleChannels(irippchan);
                        % % rippleChannels(irippchan)=rip1.getRippleEventWindowsOnly;
                        rippleEventSignalTable1{irippchan}=rip1.getRippleEventTableWithSignal;
                    end
                    rippleEventSignalTable=[];
                    for irippchan=1:numel(rippleEventSignalTable1)
                        rippleEventSignalTable=[ripplleEventSignalTable;...
                            [rippleEventSignalTable1{irippchan} ...
                            array2table(repmat(irippchan, ...
                            height(rippleEventSignalTable1{irippchan}),1), ...
                            VariableNames={'Channel'} ...
                            )]...
                            ];
                    end
                    save(frippleEventSignalTable, ...
                        'rippleEventSignalTable','-v7.3');
                else
                    s=load(frippleEventSignalTable);
                    rippleEventSignalTable=s.rippleEventSignalTable;clear s;
                    %%
                    s=rippleEventSignalTable.Signal;
                    s_tbl=[];
                    for it=1:height(rippleEventSignalTable)
                        s1=s(it);
                        s2=neuro.basic.ChannelRipple(s1);
                        % s2.plotVisualize
                        tblprop=s2.getProperties;
                        s_tbl=[s_tbl; tblprop];
                    end
                    rippleEventSignalTable.Signal=[];
                    rippleEventPropertiesTable=[rippleEventSignalTable s_tbl];
                    save(frippleEventPropertiesTable, ...
                        'rippleEventPropertiesTable','-v7.3');
                end
            end
        end
        function [] = plotRippleEventProperties(obj,sesno,win_interest)
            ses1=obj.List(obj.List.SessionNo==sesno,:);
            ses=experiment.SessionRipple(ses1.Session);
            rippleChannels=ses.getRippleChannels;
            nch=numel(rippleChannels);
            figure(1);clf;tiledlayout("vertical");
            for it=1:2*nch+1
                t(it)=nexttile();
            end
            linkaxes(t,'x')
            linkaxes(t(1:nch),'y')
            for ichan=1:numel(rippleChannels)
                ripchan=rippleChannels(ichan);
                rc=ripchan.getTimeWindow(win_interest);
                rc.RippleEvents=rc.RippleEvents.getWindow(win_interest);
                axes(t(ichan))
                rc.plot
                hold on
                rc.plotRipples
                rcds=rc.getBandpassFiltered([120 250]);
                env1=rcds.getEnvelope;
                yyaxis("right");
                rcds.plot;
                hold on
                colors=colororder;
                env1.Values=-env1.Values;
                pe=env1.plot;pe.LineWidth=1.5;pe.Color=colors(4,:);
                hold on
                env1.Values=-env1.Values;
                pe=env1.plot;pe.LineWidth=1.5;pe.Color=colors(4,:);
                axes(t(nch+1));hold on;
                pe=env1.plot;pe.LineWidth=1.5;pe.Color=colors(4,:);
                if ichan==1
                    rc.plotRipples;
                end
                axes(t(ichan+1+nch));
                tfm=rc.getTimeFrequencyMap([40 500]);
                tfm.plot
                rc.plotRipples
            end
            linkaxes(t(1:nch),'y')
        end
        function rippleEventPropertiesTableCombined = ...
                getRippleEventPropertiesTableCombined(obj)
            rippleEventPropertiesTableCombined=[];
            for ises=1:height(obj.List)
                ses1=obj.List(ises,:);
                frippleEventPropertiesTable=sprintf(...
                    "Scripts/Theta/matfiles-rip/rippleEvent_Properties_Table-ses%d.mat"...
                    ,ses1.SessionNo);
                s=load(frippleEventPropertiesTable);
                rippleEventPropertiesTable=s.rippleEventPropertiesTable;clear s;
                t1=array2table(repmat(ses1.SessionNo,height(rippleEventPropertiesTable),1), ...
                    VariableNames="Session");
                rippleEventPropertiesTable=[rippleEventPropertiesTable t1];
                rippleEventPropertiesTableCombined=[rippleEventPropertiesTableCombined;...
                    rippleEventPropertiesTable];
            end

        end
    end
end

