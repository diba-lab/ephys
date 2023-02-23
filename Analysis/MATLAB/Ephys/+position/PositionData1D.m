classdef PositionData1D < position.PositionData
    %POSITIONDATA1D Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        parent
    end
    
    methods
        function obj = PositionData1D(positionData)
            %POSITIONDATA1D Construct an instance of this class
            %   Detailed explanation goes here
            obj.parent=positionData;
            obj.units=positionData.units;
            obj.channels=positionData.channels;
            obj.time=positionData.time;
            data=positionData.getData;
            data.Z=rand(height(data),1);
            obj=obj.setData(data);            
        end
        function obj=getWindow(obj,plsd)
            [obj]=getWindow@position.PositionData(obj,plsd);
            obj.parent=obj.parent.getWindow(plsd);
        end
        function tbl = getTrialsDetected(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            tbl=obj.getUninterruptedRuns(4);
            dirs=unique(tbl.Direction);
        
            for idir=1:numel(dirs)
                idx=false(height(obj.data),1);
                dir=dirs(idir);
                tbl1=tbl(tbl.Direction==dir,:);
                for itw=1:height(tbl1)
                    tw=tbl1(itw,:);
                    idx(tw.Start:tw.Stop)=true;
                end
                objs{idir,1}=obj;
                objs{idir,1}.data.X(~idx)=nan;
                objs{idir,1}.data.Y(~idx)=nan;
                objs{idir,1}.data.Z(~idx)=nan;
            end
            tbl=table(objs,dirs,VariableNames={'Obj','Direction'});
        end
        function [tbl, idxres]= getUninterruptedRuns(obj, minCmRun)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.data.X=fillmissing(obj.data.X,"nearest");
            sp1=obj.getSpeed(1);
            sps{1}=sp1;sps{2}=sp1;
            sps{1}.Values(~(sps{1}.Values>5))=nan;%positive >5
            sps{2}.Values(~(sps{2}.Values<-5))=nan;%negative <-5
            
            sptemp=sps{1};
            sptemp.Values=[0 sptemp.Values];sptemp.Values(end)=0;
            Start=find(diff(sptemp>1)==1);
            Stop=find(diff(sptemp>1)==-1);
            startpos=obj.data.X(Start);
            stoppos=obj.data.X(Stop);
            len1=abs(stoppos-startpos);
            idx=len1>minCmRun;
            tblpos1=table(Start', Stop',VariableNames={'Start','Stop'});
            tblpos=tblpos1(idx,:);
            tblpos.Direction(:)=1;


            sptemp=sps{2};
            sptemp.Values=[0 sptemp.Values];sptemp.Values(end)=0;
            Start=find(diff(sptemp<-1)==1);
            Stop=find(diff(sptemp<-1)==-1);
            startpos=obj.data.X(Start);
            stoppos=obj.data.X(Stop);
            len1=abs(stoppos-startpos);
            idx=len1>minCmRun;
            tblneg1=table(Start', Stop',VariableNames={'Start','Stop'});
            tblneg=tblneg1(idx,:);
            tblneg.Direction(:)=-1;

            tbl=[tblpos;tblneg];
            idxres.neg=zeros(size(sp1.Values));
            idxres.pos=zeros(size(sp1.Values));
            for iw=1:height(tbl)
                w=tbl(iw,:);
                if w.Direction==1
                    idxres.pos(w.Start:w.Stop)=1;
                elseif w.Direction==-1
                    idxres.neg(w.Start:w.Stop)=1;
                end
            end
        end
        function [vel]= getSpeed(obj,smoothingWindowInSec)
            data1=table2array(obj.getData)';
            dt=diff(seconds(obj.time.getTimePoints));
            speed2=diff(data1(1,:));
            v=speed2./dt;
            if exist('smoothingWindowInSec','var')
                v=smoothdata(v,'gaussian',obj.time.getSampleRate* ...
                    smoothingWindowInSec);
            end
            vel=neuro.basic.Channel('Velocity',[0 v],obj.time);
        end
        function [p,s]= plotX(obj,scat1)
            X=obj.getDataTable.X';
            t=minutes(obj.getDataTable.TimeZT);
            p=plot(t,X,LineWidth=1);
            if exist("scat1","var")
                p.LineWidth=.5;
                val=scat1.Values';
                a=colormap(gca,"turbo");
                valc=round(normalize(val,'range',[1 256]));
                color1=nan([max(size(valc)) 3]);
                validx=~isnan(valc);
                color1(validx,:)=a(valc(validx),:);
                s=scatter(t,X,10,color1,"filled");
                s.MarkerFaceAlpha=.7;
            end
        end

    end
end

