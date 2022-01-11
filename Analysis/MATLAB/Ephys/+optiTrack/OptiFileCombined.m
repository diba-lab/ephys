classdef OptiFileCombined < neuro.time.Timelined
    %OPTIFILECOMBINED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        OptiFiles
    end
    
    methods
        function obj = OptiFileCombined(varargin)
            optiFiles=CellArrayList();
            for iArgIn=1:nargin
                optifile=varargin{iArgIn};
                assert(isa(optifile,'optiTrack.OptiFile'));
                optiFiles.add(optifile);
            end
            obj.OptiFiles=optiFiles;
        end
        function obj=plus(obj,varargin)
            for iArgIn=1:(nargin-1)
                optifile=varargin{iArgIn};
                assert(isa(optifile,'optiTrack.OptiFile'));
                obj.OptiFiles.add(optifile);
            end
            obj=obj.getSorted;
        end
        function tls=getTimeline(obj)
            iter=obj.getIterator();
            tls=[];
            i=1;
            while(iter.hasNext)
                optifile=iter.next();
                tl=optifile.getTimeline();
                tls{i}=tl;i=i+1;
            end
        end
        function ofs=getOptiFiles(obj)
            ofs=obj.OptiFiles;
        end
        function positionData=getMergedPositionData(obj)
            ofs=obj.getSorted;
            for iof=1:ofs.OptiFiles.length
                of=ofs.OptiFiles.get(iof);
                ti1=of.getTimeInterval;
                if exist('table1','var')
                    table1=[table1;of.table(:,{'X','Y','Z'})];
                    tic1=tic1+ti1;
                else
                    table1=of.table(:,{'X','Y','Z'});
                    tic1=ti1;
                end
            end
            X=table1.X;
            Y=table1.Y;
            Z=table1.Z;
            positionData=optiTrack.PositionData(X,Y,Z,tic1);
            
        end
        function obj=getSorted(obj)
            ofs=obj.OptiFiles;
            for iof=1:ofs.length
                of=ofs.get(iof);
                list(iof)=datenum(of.getStartTime);
            end
            [B,I] = sort(list);
            ofssorted=CellArrayList();
            for iof=1:ofs.length
                ofssorted.add(ofs.get(I(iof)));
            end
            obj.OptiFiles=ofs;
        end
    end
    methods (Access=private)
        function iterator=getIterator(obj)
            iterator=obj.OptiFiles.createIterator;
        end
        
    end
end

