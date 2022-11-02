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
        function tbl = getUninterruptedRuns(obj,minSecondsRun)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            minsamples=obj.time.getSampleRate*minSecondsRun;
            
            sp1=obj.getSpeed(.2);
            sps{1}=sp1;sps{2}=sp1;
            sps{1}.Values(~(sps{1}.Values>0))=nan;
            sps{2}.Values(~(sps{2}.Values<0))=nan;
            sptemp=sps{1}.getGaussianFiltered(1);
            sptemp.Values=[0 sptemp.Values];sptemp.Values(end)=0;
            Start=find(diff(sptemp>1)==1);
            Stop=find(diff(sptemp>1)==-1);
            len1=Stop-Start;
            idx=len1>minsamples;
            tblpos1=table(Start', Stop',VariableNames={'Start','Stop'});
            tblpos=tblpos1(idx,:);
            tblpos.Direction(:)=1;


            sptemp=sps{2}.getGaussianFiltered(1);
            sptemp.Values=[0 sptemp.Values];sptemp.Values(end)=0;
            Start=find(diff(sptemp<-1)==1);
            Stop=find(diff(sptemp<-1)==-1);
            len1=Stop-Start;
            idx=len1>minsamples;
            tblneg1=table(Start', Stop',VariableNames={'Start','Stop'});
            tblneg=tblneg1(idx,:);
            tblneg.Direction(:)=-1;

            tbl=[tblpos;tblneg];
        end
        function [vel]= getSpeed(obj,smoothingWindowInSec)
            data1=table2array(obj.getData)';
            dt=diff(obj.time.getTimePointsInSec);
            speed2=diff(data1(1,:));
            v=speed2./dt;
            if exist('smoothingWindowInSec','var')
                v=smoothdata(v,'gaussian',obj.time.getSampleRate* ...
                    smoothingWindowInSec);
            end
            vel=neuro.basic.Channel('Velocity',[0 v],obj.time);
        end

    end
end

