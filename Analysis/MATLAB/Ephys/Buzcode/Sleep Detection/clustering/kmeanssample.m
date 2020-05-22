clear all
home='/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG';
d1sd={'/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day01_SD/04-01-10_18-45-27_down-sampled-1250'};
d2nsd={'/data/EphysAnalysis/SleepDeprivationData/RAT_05_AG/Day02_NSD/continuous_05-00-08_18-27-11_down-sampled-1250'};
d1sd={'Day01_SD/continuous_04-01-10_08-06-28_down-sampled-1250',...
    'Day01_SD/continuous_08-10-37_12-59-53_down-sampled-1250',...
    'Day01_SD/continuous_13-18-34_14-57-00_down-sampled-1250',...
    'Day01_SD/continuous_15-00-00_18-45-27_down-sampled-1250'};
d2nsd={'Day02_NSD/continuous_05-00-08_08-00-07_down-sampled-1250',...
    'Day02_NSD/continuous_08-04-18_12-59-53_down-sampled-1250',...
    'Day02_NSD/continuous_13-12-48_14-52-31_down-sampled-1250',...
    'Day02_NSD/continuous_15-01-45_18-27-11_down-sampled-1250'};
allday=[];
days={d2nsd,d1sd};
animal='AG';
methods={'dbscan','kmeans'};
daycodes={'Day02, NSD','Day01,SD'};
epsilons=[.11 .09];
minptss=[900 800];
for imethod=1:numel(methods)
    for iday=1:numel(days)
        for ik=[8]
            day=days{iday};
            for ifold=1:numel(day)
                session=[];
                a=dir([home filesep day{ifold} filesep '*.SleepScoreMetrics.mat']);
                load(fullfile(a.folder,a.name))
                session(:,3) = SleepScoreMetrics.EMG;
                session(:,2) = SleepScoreMetrics.thratio;
                session(:,1) = SleepScoreMetrics.broadbandSlowWave;
                allday=vertcat(allday,session);
            end
            [numInst,numDims] = size(allday);
            
            %# K-means clustering
            %# (K: number of clusters, G: assigned groups, C: cluster centers)
            K = ik;
            param.K=K;
            param.epsilon=epsilons(iday);
            param.minpts=minptss(iday);
            s=SleepCluster(methods{imethod},param);
            cluster = s.runCluster(allday);
            
            %     gm = fitgmdist(allday,4);
            % idx = cluster(gm,allday);
            
            figure
            cluster.plot
            view(3), axis vis3d, box on, rotate3d on
            xlabel('SlowWave'), ylabel('Theta'), zlabel('EMG')
            titlestr=[methods{imethod} ', ' animal ', ' daycodes{iday}];
            title(titlestr);
            %     FigureFactory.instance.save(['sd_' num2str(sessions) '_' num2str(K)])
        end
    end
end