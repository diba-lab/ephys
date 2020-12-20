classdef OptiFileCombined < Timelined
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
                assert(isa(optifile,'OptiFile'));
                optiFiles.add(optifile);
            end
            obj.OptiFiles=optiFiles;
        end
        function obj=plus(obj,varargin)
            for iArgIn=1:(nargin-1)
                optifile=varargin{iArgIn};
                assert(isa(optifile,'OptiFile'));
                obj.OptiFiles.add(optifile);
            end
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
        function tic=getTimeInterval(obj)
            iter=obj.getIterator();
            while(iter.hasNext)
                optifile=iter.next();
                ti=optifile.getTimeInterval();
                if exist('tic','var')
                    tic=tic+ti;
                else
                    tic=ti;
                end
            end
        end
        function chans=getChannels(obj,vars)
            files=obj.OptiFiles.createIterator;
            while(files.hasNext)
                aFile=files.next;
                t=aFile.table;
                if ~exist('vars','var')
                    vars=t.Properties.VariableNames;
                end
                for iDimension=1:numel(vars)
                    dim=vars{iDimension};
                    aDim=t.(dim);
                    aChan= Channel(dim, aDim, aFile.getTimeInterval);
                    chan.(dim)=aChan;
                end
                if ~exist('chans','var')
                    chans=chan;
                else
                    for iDimension=1:numel(vars)
                        dim=vars{iDimension};
                        chans.(dim)=chans.(dim)+chan.(dim);
                    end
                end
            end
        end
        function ofs=getOptiFiles(obj)
            ofs=obj.OptiFiles;
        end
    end
    methods (Access=private)
        function iterator=getIterator(obj)
            iterator=obj.OptiFiles.createIterator;
        end
    end
end

