classdef PositionData
    %LOCATIONDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        X
        Y
        Z
        timeIntervalCombined
        units
        source
    end
    
    methods
        function obj = PositionData(X,Y,Z,ticd)
            %LOCATIONDATA Construct an instance of this class
            %   Detailed explanation goes here
            if ischar(X)&&isfolder(X)
                obj=obj.loadPlainFormat(X);
            elseif numel(X)==numel(Y)&&numel(Z)==numel(Y)&&numel(X)==ticd.getNumberOfPoints
                obj.X = X;
                obj.Y = Y;
                obj.Z = Z;
                obj.timeIntervalCombined = ticd;
                obj.units='cm';
            else
                error('Sizes of XYZ or time are not equal.')
            end
        end
        function pd=getWindow(obj,plsd)
            ticd=obj.timeIntervalCombined;
            pd=obj;
            window=ticd.getTimeIntervalForTimes(plsd);
            pd.timeIntervalCombined=window;
            samples=ticd.getSampleForClosest(plsd);
            idx=samples(1):samples(2);
            pd.X=obj.X(idx);
            pd.Y=obj.Y(idx);
            pd.Z=obj.Z(idx);
        end
        function [X,Y,Z,idx]= getPositionForTimesBoth(obj,times,speedthreshold)
            ticd=obj.timeIntervalCombined;
            speedTrack=obj.getSpeed;
            thresholded=speedTrack.getAboveAbs(speedthreshold);
            if ~exist([DataHash(times) '.mat'],'file')
                for itime=1:numel(times)
                    sampleno(itime)=ticd.getSampleFor(times(itime));
                end
                save(DataHash(times),'sampleno')
            else
                load(DataHash(times));
            end
            idx=ismember(sampleno,find(thresholded));
            X=obj.X(sampleno);
            Y=obj.Y(sampleno);
            Z=obj.Z(sampleno);
            
        end
        function [X,Y,Z,idx]= getLocationForTimesNeg(obj,times,speedthreshold)
            ticd=obj.timeIntervalCombined;
            speedTrack=obj.getSpeed;
            thresholded=speedTrack.getBelow(speedthreshold);
            if ~exist([DataHash(times) '.mat'],'file')
                for itime=1:numel(times)
                    sampleno(itime)=ticd.getSampleFor(times(itime));
                end
                save(DataHash(times),'sampleno')
            else
                load(DataHash(times));
            end
            idx=ismember(sampleno,find(thresholded));
            X=obj.X(sampleno);
            Y=obj.Y(sampleno);
            Z=obj.Z(sampleno);
            
        end
        function [X,Y,Z,idx]= getLocationForTimesPos(obj,times,speedthreshold)
            ticd=obj.timeIntervalCombined;
            speedTrack=obj.getSpeed;
            thresholded=speedTrack.getAbove(speedthreshold);
            if ~exist([DataHash(times) '.mat'],'file')
                for itime=1:numel(times)
                    sampleno(itime)=ticd.getSampleFor(times(itime));
                end
                save(DataHash(times),'sampleno')
            else
                load(DataHash(times));
            end
            idx=ismember(sampleno,find(thresholded));
            X=obj.X(sampleno);
            Y=obj.Y(sampleno);
            Z=obj.Z(sampleno);
            
        end
        function [spkArr]= getSpikeArray(obj,times)
            ticd=obj.timeIntervalCombined;
            spkArr=zeros(size(obj.X));
            for itime=1:numel(times)
                sampleno=ticd.getSampleFor(times(itime));
                spkArr(sampleno)=spkArr(sampleno)+1;
            end
            
        end
        function outputArg = plot(obj)
            numPointsInPlot=1000;
            ticd=obj.timeIntervalCombined;
            t_org=ticd.getTimePointsInSec-seconds(ticd.getZeitgeberTime-ticd.getStartTime);
            downsamplefactor=round(numel(t_org)/numPointsInPlot);
            X=downsample(medfilt1(obj.X,ticd.getSampleRate),downsamplefactor);
            Y=downsample(medfilt1(obj.Y,ticd.getSampleRate),downsamplefactor);
            Z=downsample(medfilt1(obj.Z,ticd.getSampleRate),downsamplefactor);
            t=hours(seconds(downsample(t_org,downsamplefactor)));
            
            plot(t,X);hold on;
            plot(t,Y);
            plot(t,Z);
            legend({'X','Y','Z'});
            xlabel('ZT (Hrs)');
            ylabel(['Location (',obj.units,')']);
            ax=gca;
            
        end
        function outputArg = plotZ(obj)
            numPointsInPlot=3000;
            ticd=obj.timeIntervalCombined;
            t_org=ticd.getTimePointsInSec;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);
            X=downsample(medfilt1(obj.X,ticd.getSampleRate),downsamplefactor);
            Y=downsample(medfilt1(obj.Y,ticd.getSampleRate),downsamplefactor);
            Z=downsample(medfilt1(obj.Z,ticd.getSampleRate),downsamplefactor);
            t=minutes(seconds(downsample(t_org,downsamplefactor)));
            hold on;
            %             plot(t,X);
            %             plot(t,Y);
            plot(Z,t);
            legend({'Z'});
            ylabel('Time (minutes)');
            xlabel(['Location (',obj.units,')']);
            ax=gca;
            ax.XLim=[min(Z) max(Z)];
            
            %             ax.YDir='reverse';
            
        end
        function []=plotSpikes(obj, spikeUnits)
            figure
            obj.plot;hold on
            colors=linspecer(numel(spikeUnits),'qualitative');
            ticd=obj.timeIntervalCombined;
            ts=minutes(seconds(ticd.getTimePointsInSec));
            for iunit=1:numel(spikeUnits)
                su=spikeUnits(iunit);
                times=su.getAbsoluteSpikeTimes;
                for itime=1:numel(times)
                    color=colors(iunit,:);
                    sampleno=ticd.getSampleFor(times(itime));
                    t=ts(sampleno);
                    X=obj.X(sampleno);
                    Y=obj.Y(sampleno);
                    Z=obj.Z(sampleno);
                    p1=plot(t,Z,'Marker','.',...
                        'MarkerEdgeColor',color,...
                        'MarkerFaceColor',color,...
                        'MarkerSize',10);hold on;
                    %                     p1=plot(t,X);hold on;
                    %                     p1=plot(t,Y);hold on;
                    legend off;
                end
            end
            
        end
        function outputArg = plot3D(obj)
            numPointsInPlot=100000;
            ticd=obj.timeIntervalCombined;
            t_org=ticd.getTimePointsInSec;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);
            X=downsample(medfilt1(obj.X,ticd.getSampleRate),downsamplefactor);
            Y=downsample(medfilt1(obj.Y,ticd.getSampleRate),downsamplefactor);
            Z=downsample(medfilt1(obj.Z,ticd.getSampleRate),downsamplefactor);
            %             t=minutes(seconds(downsample(t_org,downsamplefactor)));
            %             clr=linspecer(numel(X));
            plot3(Z,X,Y,'Color',[.8 .8 .8])
            xlabel('front-back');
            ylabel('left-right');
            zlabel('up-down');
            ax=gca;
            ax.DataAspectRatio=[1 1 1]
            
        end
        function outputArg = plot2D(obj)
            numPointsInPlot=100000;
            ticd=obj.timeIntervalCombined;
            t_org=ticd.getTimePointsInSec;
            downsamplefactor=round(numel(t_org)/numPointsInPlot);
            X=downsample(medfilt1(obj.X,ticd.getSampleRate),downsamplefactor);
            Z=downsample(medfilt1(obj.Z,ticd.getSampleRate),downsamplefactor);
            %             t=minutes(seconds(downsample(t_org,downsamplefactor)));
            %             clr=linspecer(numel(X));
            plot(X,Z,'Color',[.8 .8 .8])
            ylabel('front-back');
            xlabel('left-right');
            ax=gca;
            ax.DataAspectRatio=[1 1 1]
            
        end
        function outputArg = plot2Dabove(obj,th)
            ind_track=obj.getSpeed.getAbove(th);
            X=obj.X(ind_track);
            Z=obj.Z(ind_track);
            %             t=minutes(seconds(downsample(t_org,downsamplefactor)));
            %             clr=linspecer(numel(X));
            plot(Z,X,'Color',[.8 .8 .8])
            xlabel('front-back');
            ylabel('left-right');
            ax=gca;
            ax.DataAspectRatio=[1 1 1]
            
        end
        function []=plotSpikes3D(obj, spikeUnits)
            figure
            %             obj.plot3D;hold on
            colors=linspecer(numel(spikeUnits),'qualitative');
            ticd=obj.timeIntervalCombined;
            for iunit=1:numel(spikeUnits)
                su=spikeUnits(iunit);
                times=su.getAbsoluteSpikeTimes;
                for itime=1:numel(times)
                    sampleno=ticd.getSampleFor(times(itime));
                    X=obj.X(sampleno);
                    Y=obj.Y(sampleno);
                    Z=obj.Z(sampleno);
                    p1=plot3(Z,X,Y);hold on;
                    p1.Marker='.';
                    p1.MarkerFaceColor=colors(iunit,:);
                    p1.MarkerEdgeColor=colors(iunit,:);
                    p1.MarkerSize=10;
                    legend off;
                end
            end
            ax=gca;
            ax.DataAspectRatio=[1 1 1];
            
        end
        function newLocData = getTimeWindow(obj,timeWindow)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            ticd=obj.timeIntervalCombined;
            ticdnew=ticd.getTimeIntervalForTimes(timeWindow(1),timeWindow(2));
            s1=ticd.getSampleFor(ticdnew.getStartTime);
            s2=ticd.getSampleFor(ticdnew.getEndTime);
            newLocData=LocationData(obj.X(s1:s2),obj.Y(s1:s2),obj.Z(s1:s2),ticdnew);
        end
        function obj = getDownsampled(obj,dsfactor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            X=obj.X;
            Y=obj.Y;
            Z=obj.Z;
            ticd=obj.timeIntervalCombined;
            
            dsfactor=round(numel(X)/numPointsInPlot);
            obj.X=downsample(medfilt1(X,dsfactor),dsfactor);
            obj.Y=downsample(medfilt1(Y,dsfactor),dsfactor);
            obj.Z=downsample(medfilt1(Z,dsfactor),dsfactor);
            t=downsample(minutes(seconds(ticd.getTimePointsInSec)),dsfactor);
        end
        function obj = getSpeed(obj)
            obj.X=diff(obj.X)*obj.timeIntervalCombined.getSampleRate;
            obj.Y=diff(obj.Y)*obj.timeIntervalCombined.getSampleRate;
            obj.Z=diff(obj.Z)*obj.timeIntervalCombined.getSampleRate;
            obj.X(numel(obj.X)+1)=obj.X(end);
            obj.Y(numel(obj.Y)+1)=obj.Y(end);
            obj.Z(numel(obj.Z)+1)=obj.Z(end);
            obj.units='cm/s';
        end
        function obj = setSpeedThreshold(obj,th)
            obj.SpeedThreshold=th;
        end
        function ind = getAbove(obj,threshold)
            ind=obj.Z>=threshold;
        end
        function ind = getAboveAbs(obj,threshold)
            ind=abs(obj.Z)>=threshold;
        end
        function ind = getBelow(obj,threshold)
            ind=obj.Z<=threshold;
        end
        function file1 = saveInPlainFormat(obj,folder)
            if exist('folder','var')
                if ~isfolder(folder)
                    folder= pwd;
                end
            else
                folder= fileparts(obj.source);
            end
            x=obj.X;
            y=obj.Y;
            z=obj.Z;
            time=obj.timeIntervalCombined;
            time.saveTable(fullfile(folder,'position.time.csv'));
            t=array2table([x y z],'VariableNames',{'x','y','z'});
            file1=fullfile(folder,'position.points.csv');
            writetable(t,file1);
        end
        function obj = loadPlainFormat(obj,folder)
            if exist('folder','var')
                if ~isfolder(folder)
                    folder= pwd;
                end
            else
                folder= pwd;
            end
            file1=fullfile(folder,'position.points.csv');
            t=readtable(file1);
            obj.source=file1;
            obj.X=t.x;
            obj.Y=t.y;
            obj.Z=t.z;
            obj.timeIntervalCombined=neuro.time.TimeIntervalCombined(fullfile(folder,'position.time.csv'));
        end
    end
end

