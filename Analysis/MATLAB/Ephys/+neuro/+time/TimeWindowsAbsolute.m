classdef TimeWindowsAbsolute<neuro.time.TimeWindows
    %TIMEWINDOWS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimeTable
        TimeIntervalCombined
    end
    
    methods
        function obj = TimeWindowsAbsolute(timeTable,ticd)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least 
            % two datetime value columns: Start, Stop
            if isstruct(timeTable)
                timeTable=struct2table(timeTable);
            end
            obj.TimeTable = timeTable;
            if exist('ticd','var'), obj.TimeIntervalCombined=ticd; end
        end
        function t = getTimeTable(this)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least 
            % two datetime value columns: Start, Stop
            t=this.TimeTable;
        end
        function this = SetTimeIntervalCombined(this,ticd)
            %TIMEWINDOWS Construct an instance of this class
            %   Time Table should have at least 
            % two datetime value columns: Start, Stop
            this.TimeIntervalCombined=ticd;
        end
        function obj = mergeOverlaps(obj,minDurationBetweenEvents)
            T=obj.TimeTable;
            firstPass=[T.Start T.Stop];
            firstType=T.Type;
            secondType=[];
            secondPass=[];
            theArt = firstPass(1,:);
            theType=firstType(1);
            for i = 2:size(firstPass,1)
                if firstPass(i,1) - theArt(2) < minDurationBetweenEvents % overlap?
                    % Merge
                    [theArt(1), theArt(2)]= bounds([theArt firstPass(i,:)]);
                else
                    secondPass = [secondPass ; theArt];
                    secondType=[secondType; theType];
                    theArt = firstPass(i,:);
                    theType=firstType{i};
                end
            end
            tnew=table(secondPass(:,1),secondPass(:,2),secondType,'VariableNames',{'Start','Stop','Type'});
            obj=neuro.basic.TimeWindows(tnew,obj.TimeIntervalCombined);
        end
        
        function timeWindows = plus(thisTimeWindows,newTimeWindows)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            t1=thisTimeWindows.TimeTable;
            t2=newTimeWindows.TimeTable;
            tRes=t1;
            tRes(:,:)=[];
            art_count=0;%count on result;
            for iwin=1:height(t1)
                art_base=t1(iwin,:);
                base.start=art_base.Start;
                base.stop=art_base.Stop;
                
                new_start_is_in_old=(t2.Start>base.start & t2.Start<base.stop);
                new_stop_is_in_old=(t2.Stop>base.start & t2.Stop<base.stop);
                old_start_is_in_new=(base.start>t2.Start & base.start<t2.Stop);
                old_stop_is_in_new=(base.stop>t2.Start & base.stop<t2.Stop);
                idx=new_start_is_in_old|new_stop_is_in_old|old_start_is_in_new|old_stop_is_in_new;
                if sum(idx)>0 % take the first one
                    x=find(idx);
                    idx1=false(size(idx));
                    idx1(x(1))=true; 
                    idx=idx1;
                end
                artifactHasNoOverlap=~sum(idx);
                if artifactHasNoOverlap
                    art_count=art_count+1;% no overlap: put the base
                    tRes(art_count,:)=art_base;
                else % overlap: merge and put the merged, remove from new
                    art_new=t2(idx,:);t2(idx,:)=[];%remove new
                    if (art_new.Stop-art_new.Start)>(art_base.Stop-art_base.Start)
                        art_base.Type=art_new.Type;
                    end
                    if art_new.Start<art_base.Start, art_base.Start=art_new.Start;end
                    if art_new.Stop>art_base.Stop, art_base.Stop=art_new.Stop;end
                    art_count=art_count+1;
                    tRes(art_count,:)=art_base;
                end
            end
            tRes=[tRes;t2];
            tRes=sortrows(tRes, 'Start');
            timeWindows=neuro.basic.TimeWindows(tRes,thisTimeWindows.TimeIntervalCombined);
%             timeWindows=timeWindows.mergeOverlaps(seconds(.5));
        end
        function ax=plot(obj,ax)
            T=obj.TimeTable;
            start=T.Start;
            stop=T.Stop;
            type=T.Type;
            types= {'ZScored_RawLFP','ZScored_Power 1-4 Hz',...
                'ZScored_Power 4-12 Hz', 'ZScored_Power 20-80 Hz',...
                'ZScored_Power 140-250 Hz'};
            colors=linspecer(numel(types));
            if ~exist('ax','var'), ax=gca;end
            hold on;
            for iart=1:numel(start)
                x=[start(iart) stop(iart)];
                y=[ax.YLim(2) ax.YLim(2)];
                text(mean(x),mean(ax.YLim),num2str(iart));
                p=area(ax,x,y);
                p.BaseValue=ax.YLim(1);
                p.FaceAlpha=.5;
                try
                    colorno=ismember(types,type{iart});
                catch
                    colorno=ismember(types,type);
                end
                p.FaceColor=colors(colorno,:);
                p.EdgeColor='none';
            end
        end
        function file=saveForClusteringSpyKingCircus(obj,file)
            t=obj.TimeTable;
            time=obj.TimeIntervalCombined;
            for it=1:height(t)
                t1=t(it,1:2);
                
                samples=time.getSampleForClosest([t1.Start t1.Stop]);
                timeMS(it,:)= (samples/time.getSampleRate)*1000;
            end
            writematrix(timeMS,file,'Delimiter',' ');
        end
        function ax=saveForNeuroscope(obj,pathname)
            T=obj.TimeTable;
%             start=T.Start;
%             stop=T.Stop;
            ctd=neuro.basic.ChannelTimeDataHard(pathname);
            ticd=ctd.getTimeIntervalCombined;
            files = dir(fullfile(pathname,'*Bad.R*.evt'));
            if isempty(files)
                fileN = 1;
            else
                %set file index to next available value\
                pat = 'Bad.R[0-9].';
                fileN = 0;
                for ii = 1:length(files)
                    token  = regexp(files(ii).name,pat);
                    val    = str2double(files(ii).name(token+2:token+4));
                    fileN  = max([fileN val]);
                end
                fileN = fileN + 1;
            end
            tokens=split(pathname,filesep);
            filename=tokens{end};
            fid = fopen(sprintf('%s%s%sBad.R%02d.evt',pathname,filesep,filename,fileN),'w');
            
            % convert detections to milliseconds
            T= obj.TimeTable;
            start=seconds(T.Start-ticd.getStartTime)*1000;
            stop=seconds(T.Stop-ticd.getStartTime)*1000;
            fprintf(1,'Writing event file ...\n');
            for ii = 1:size(start,1)
                fprintf(fid,'%9.1f\tstart\n',start(ii));
                fprintf(fid,'%9.1f\tstop\n',stop(ii));
            end
            fclose(fid);
        end
        function ax=getArrayForBuzcode(obj,ax)
            T=obj.TimeTable;
            start=T.Start;
            stop=T.Stop;
            if ~exist('ax','var'), ax=gca;end
            hold on;
            for iart=1:numel(start)
                x=[start(iart) stop(iart)];
                y=[ax.YLim(2) ax.YLim(2)];
                p=area(ax,x,y);
                p.BaseValue=ax.YLim(1);
                p.FaceAlpha=.5;
                p.FaceColor='r';
                p.EdgeColor='none';
            end
        end
    end
end

