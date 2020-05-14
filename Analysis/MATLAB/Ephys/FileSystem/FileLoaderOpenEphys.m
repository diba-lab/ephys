classdef FileLoaderOpenEphys < FileLoaderMethod
    %FILELOADEROPENEPHYS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        openephysFile
        xmlfile
        chunksize
        downsample
        outFileForTemporaries
        Record1Lantency
    end
    
    methods
        function obj = FileLoaderOpenEphys(openephysFile)
            %FILELOADERBINARY Construct an instance of this class
            %   Detailed explanation goes here
            obj.openephysFile=openephysFile;
            [filepath,fname,~]=fileparts(obj.openephysFile);
            obj.outFileForTemporaries=fullfile(filepath,'bin',...
                'TimeAndInfo.mat');
            listing=dir(fullfile(filepath,'settings*.xml'));
            if numel(listing)>1
                experimentno=str2double(fname(end));
                xmlfile=fullfile(listing(1).folder,sprintf(...
                    'settings_%d.xml',experimentno));
            else
                xmlfile=fullfile(listing.folder,listing.name);
            end
            obj.xmlfile=xmlfile;
            obj.chunksize=2e6;
            obj.downsample=1250;
        end
        
        function openEphysRecord = load(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outfile=obj.outFileForTemporaries;
            [outfolder,~,~]=fileparts(obj.outFileForTemporaries);
            
            if ~exist(outfile,'file')
                obj.convertChannelFilesToBinary();
            end
            load(obj.outFileForTemporaries);
            S=xml2struct(obj.xmlfile);
            starttime=datetime(S.SETTINGS.INFO.DATE.Text ,'InputFormat',...
                'dd MMM yyyy HH:mm:ss');
            oefile=xml2struct(obj.openephysFile);
            [filepath1,oefilename,~]=fileparts(obj.openephysFile);
            newlfpfileName = fullfile(filepath1, [oefilename, '.dat']);
            channels=oefile.EXPERIMENT.RECORDING.PROCESSOR.CHANNEL;
            if ~exist(newlfpfileName,'file')
                for ichan=1:numel(channels)
                    achan1=channels{ichan};
                    [~,name,~]=fileparts(achan1.Attributes.filename);
                    chfile=fullfile(outfolder,name);
                    
                    channelFiles{ichan}=memmapfile(chfile,'Format',...
                        {'int16',[1 numel(timestamps)],'voltageArray'});
                end
                
                
                numchunk=ceil(size(timestamps,1)/obj.chunksize);
                for ichunk=1:numchunk
                    tic
                    chunkbegin=(ichunk-1)*obj.chunksize+1;
                    if ichunk~=numchunk
                        chunkend=ichunk*obj.chunksize;
                    else
                        chunkend=chunkbegin-1+mod(size(timestamps,1),obj.chunksize);
                    end
                    data=zeros(numel(channels),chunkend-chunkbegin+1);
                    for ichan=1:numel(channels)
                        channelFile=channelFiles{ichan};
                        data(ichan,:)=channelFile.Data.voltageArray(chunkbegin:chunkend);
                    end
                    
                    fileID = fopen(newlfpfileName, 'a');
                    fwrite(fileID, data,'int16');
                    fclose(fileID);
                    toc
                end
            end
            file=dir(newlfpfileName);
            samples=file.bytes/2/numel(channels);
            Data=memmapfile(newlfpfileName,'Format',{'int16'...
                [numel(channels) samples] 'mapped'});
            info.header.SettingsAtXMLFile=S.SETTINGS;
            info.header.StartTime=starttime+seconds(timestamps(1));
            
            openEphysRecord.Header=info.header;
            openEphysRecord.Data=Data;
            timestamps=timestamps-timestamps(1);
            ts=timeseries(nan(numel(timestamps),1),timestamps);
            ts.TimeInfo.Format='dd-mmm-yyyy HH:MM:SS.FFF';
            ts.TimeInfo.StartDate=starttime;
            openEphysRecord.Timestamps=ts;
            openEphysRecord.DataFile=newlfpfileName;
            
        end
    end
    methods (Access=private)
        function []=convertChannelFilesToBinary(obj)
            oefile=xml2struct(obj.openephysFile);
            [filepath1,~,~]=fileparts(obj.openephysFile);
            channels=oefile.EXPERIMENT.RECORDING.PROCESSOR.CHANNEL;
            
            [outfolder,~,~]=fileparts(obj.outFileForTemporaries);
            
            achan1=channels{1};
            achan=achan1.Attributes;
            filename=achan.filename;
            filepath=fullfile(filepath1,filename);
            
            
            for ichan=1:numel(channels)
                achan1=channels{ichan};
                achan=achan1.Attributes;
                filename=achan.filename;
                filepath=fullfile(filepath1,filename);
                
                tic;
                [data, ~, ~]= load_open_ephys_data_faster(...
                    filepath,'unscaledInt16');
                toc;
                
                [~,name,~]=fileparts(filename);
                if ~exist(outfolder,'dir')
                    mkdir(outfolder)
                end
                outfile=fullfile(outfolder,name);
                fileID = fopen(outfile,'w');
                fwrite(fileID, data,'int16');
                fclose(fileID);
            end
            tic;
            [~, timestamps, info]= load_open_ephys_data_faster(...
                filepath,'unscaledInt16');
            toc;
            save(obj.outFileForTemporaries,'timestamps','info','-v7.3');
        end
    end
end