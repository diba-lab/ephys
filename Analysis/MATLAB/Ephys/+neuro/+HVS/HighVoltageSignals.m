classdef HighVoltageSignals < neuro.event.Events
    %HIGHVOLTAGESIGNALS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Parameters
        TimeWindows
    end
    
    methods
        function obj = HighVoltageSignals(dataForLFP, params)
            %HIGHVOLTAGESIGNALS Construct an instance of this class
            %   Detailed explanation goes here
            if ~exist('params','var')||isempty(params)
                obj.Parameters = dataForLFP.AnalysisParameters.HVS;
            else
                obj.Parameters =params;
            end
            folder=fileparts(dataForLFP.DataFile);
            cachefile=fullfile(folder,'cache',['HVS' DataHash(obj.Parameters) '.mat']);
            if ~isfile(cachefile)
                ctdh=dataForLFP.getChannelTimeDataHard;
                bad=dataForLFP.getBad;
%                 ctdhb=ctdh.setBad(bad);
                for ichan=1:numel(obj.Parameters.Channel)
                    ch1=obj.Parameters.Channel(ichan);
                    ch=ctdh.getChannel(ch1);
                    tf=ch.getTimeFrequencyMap(neuro.tf.TimeFrequencyChronuxMtspecgramc(...
                        [obj.Parameters.FrequencyTheta(1) obj.Parameters.FrequencyAboveTheta(2)],[2 1]));
                    mtf1=tf.getMeanFrequency(obj.Parameters.FrequencyTheta);
                    mtfa1(ichan,:)= mtf1';
                    mtf2=tf.getMeanFrequency(obj.Parameters.FrequencyAboveTheta);
                    mtfa2(ichan,:)= mtf2';
                end
                for ichan=1:numel(obj.Parameters.ChannelHC)
                    ch1=obj.Parameters.ChannelHC(ichan);
                    ch=ctdh.getChannel(ch1);
                    tf=ch.getTimeFrequencyMap(neuro.tf.TimeFrequencyChronuxMtspecgramc(...
                        [obj.Parameters.FrequencyTheta(1) obj.Parameters.FrequencyAboveTheta(2)],[2 1]));
                    mtf1=tf.getMeanFrequency(obj.Parameters.FrequencyTheta);
                    mtfhca1(ichan,:)= mtf1';
                    mtf2=tf.getMeanFrequency(obj.Parameters.FrequencyAboveTheta);
                    mtfhca2(ichan,:)= mtf2';
                end
                
                
                
                sdd=dataForLFP.getStateDetectionData;
                ss=sdd.getStateSeries;
                idx11= zscore(mean(mtfa1,1))>obj.Parameters.ThresholdZScoreTheta;
                nonidx1=zscore(mean(mtfhca1,1))>obj.Parameters.ThresholdZScoreTheta*2;
                idx1=idx11&~nonidx1;
                idx22=zscore(mean(mtfa2,1))>obj.Parameters.ThresholdZScoreAboveTheta;
                nonidx2=zscore(mean(mtfhca2,1))>obj.Parameters.ThresholdZScoreTheta*2;
                idx2=idx22&~nonidx2;
                
                artifact=ss.States'==0;
                HVSeventidx=zeros(size(artifact));
                HVSeventidx=HVSeventidx|(idx1&idx2);
                HVSeventidx=HVSeventidx&~artifact;
                HVSeventidx=[0 HVSeventidx 0];
                edges=diff(HVSeventidx);
                Start=seconds(find(edges==1)'); Stop=seconds(find(edges==-1)');
                t=table(Start,Stop);
                tw2=neuro.time.TimeWindowsDuration(t);
                pr=preprocessing.Preprocess(experiment.Session(fileparts(dataForLFP.DataFile)));
                bad=pr.Bad;
                tw1=tw2-bad;
                tw=tw1.mergeOverlaps(obj.Parameters.MinimumInterEventIntervalInSec);
                save(cachefile,'tw');
            else
                S=load(cachefile);
                tw=S.tw;
            end
            tt=tw.getTimeTable;
            
            for ievent=1:height(tt)
                
            end
            folder=fileparts(dataForLFP.DataFile);
            tw.saveForNeuroscope(folder,'HVS');
            bcevent=buzcode.BuzcodeEvents(tw);bcevent.EventsFolder=folder;
            bcevent.savemat;
            obj.TimeWindows=tw;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

