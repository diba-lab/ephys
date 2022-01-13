classdef OptiCSVFileSingleMarker<optiTrack.OptiCSVFile
    %OPTICSVFILESINGLEMARKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function newobj = OptiCSVFileSingleMarker(file)
            %OPTICSVFILESINGLEMARKER Construct an instance of this class
            %   Detailed explanation goes here
            newobj@optiTrack.OptiCSVFile(file);
            newobj= newobj.loadData(file);
        end
        
        function obj = loadData(obj,file)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% Single Marker
            if ~exist("file","var")
                file=obj.file;
            end
       
            opts = detectImportOptions(file,"ReadVariableNames",true,VariableNamesLine=7);
            opts.VariableNames(1:5) = {'Frame', 'Time', 'X', 'Y', 'Z'};
            opts.VariableTypes(1:2)={'uint32','double'};
            opts.VariableTypes(3:end)={'double'};
            opts.DataLines=[8 inf];
            opts.ExtraColumnsRule = 'ignore';
            opts.EmptyLineRule = 'read';
            T=readtable(file,opts);
            obj.table = T;
        end
        function st=getStartTime(obj)
            st=obj.CaptureStartTime;
        end
        function sr=getSampleRate(obj)
            sr=obj.ExportFrameRate;
        end
        function nf=getNumFrames(obj)
            nf=obj.TotalExportedFrames;
        end
        function positionData=getMergedPositionData(obj)
            tic1=obj.getTimeInterval;
            prompt = {'Scale cm:'};
            dlgtitle = datestr(tic1.getDate);
            dims = [1 10];
            definput = {'0.5'};
            scale = str2double(inputdlg(prompt,dlgtitle,dims,definput));
            table1=obj.table;
            dims={'X','Y','Z'};
            reflectionpoints={[-15 inf; 97.8 98.4; 115 130], [60 95; -inf 6; -6 30], [-75 -49; 12 18; 58 70], ...
                [-75 -50; 2 10; 68.8 69.6], [10 25; 2 23; 50 65], [10 25; 2 23; -6 6], [-62 -52 ; 14 22; 48 52]};
            figure(1);
            for idim=1:numel(dims)
                dim{idim}=table2array(table1(:,startsWith(table1.Properties.VariableNames,dims{idim})))*scale;
                subplot(numel(dims),10,(idim-1)*10+(1:9));plot(table1.Time,dim{idim});ax=gca;
                subplot(numel(dims),10,(idim-1)*10+10);histogram(dim{idim},BinWidth=.2);
                ax2=gca;ax2.XLim=ax.YLim;view([90 -90])
            end
            figure(2);
            idxs=false(size(dim{1}));
            for iref=1:numel(reflectionpoints)
                refp=reflectionpoints{iref}*scale;
                idxh=true(size(dim{1}));
                for idim=1:numel(dims)
                    lim1=refp(idim,:);
                    dim1=dim{idim};
                    idxh=idxh&(dim1>lim1(1)&dim1<lim1(2));
                end
                idxs=idxs|idxh;
            end
            for idim=1:numel(dims)
                dim1=dim{idim};
                dim1(idxs)=nan;
                dim1filt=nan([1 size(dim1,1)]);
                winlength=tic1.getSampleRate*.2;
                for it=1:numel(dim1filt)
                    range=[it-round(winlength/2) it+round(winlength/2)];
                    if range(1)<1,range(1)=1;end
                    if range(2)>numel(dim1filt),range(2)=numel(dim1filt);end
                    dim1filt(it)=median(dim1(range,:),'all','omitnan');
                end
                dim1filt2(idim,:)=medfilt1(dim1filt,round(winlength*2),'omitnan');
                subplot(numel(dims),10,(idim-1)*10+(1:9));plot(table1.Time,dim1);ax=gca;
                hold on;plot(table1.Time,dim1filt2(idim,:),LineWidth=1.5,Color='k');hold off
                subplot(numel(dims),10,(idim-1)*10+10);histogram(dim1filt2(idim,:),BinWidth=.2);
                ax2=gca;ax2.XLim=ax.YLim;view([90 -90])
            end
            
            X=dim1filt2(1,:);
            Y=dim1filt2(2,:);
            Z=dim1filt2(3,:);
            prompt = {'Zeitgeber Time:'};
            dlgtitle = datestr(tic1.getDate);
            dims = [1 10];
            definput = {'08:00'};
            zt = duration(inputdlg(prompt,dlgtitle,dims,definput),'InputFormat','hh:mm');
            tic1=tic1.setZeitgeberTime(zt);
            positionData=optiTrack.PositionData(X,Y,Z,tic1);
        end

    end
end

