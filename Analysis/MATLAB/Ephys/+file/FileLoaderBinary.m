classdef FileLoaderBinary < file.FileLoaderMethod
    %FILELOADERBINARY Summary of this class goes here
    %   Detailed explanation goes here

    properties
        OEBinFile
        xmlfile
        Record1Lantency
    end

    methods
        function obj = FileLoaderBinary(oeBinFile)
            %FILELOADERBINARY Construct an instance of this class
            %   Detailed explanation goes here
            obj.OEBinFile=oeBinFile;
            [filepath,~,~]=fileparts(obj.OEBinFile);
            try
                listing=dir(fullfile(filepath,'..','..','*.xml'));
                if numel(listing)>1
                    listing1=dir(fullfile(filepath,'..'));
                    experimentno=str2double(listing1(1).folder(end));
                    if experimentno>1
                        xmlfile=fullfile(listing(1).folder, sprintf( ...
                            'settings_%d.xml',experimentno));
                    else
                        xmlfile=fullfile(listing(1).folder, sprintf( ...
                            'settings_%d.xml',experimentno));
                        if ~isfile(xmlfile)
                            xmlfile=fullfile(listing(1).folder, sprintf( ...
                                'settings.xml'));
                        end
                    end
                else
                    xmlfile=fullfile(listing.folder,listing.name);
                end
                obj.xmlfile=xmlfile;
            catch
                warning(['Settings .XML file couldn''t be found in folder' ...
                    '\n%s\nIt should be in ../.. relative to .oebin' ...
                    ' file\n'],listing(1).folder);
                [file,path] = uigetfile('*.xml');
                obj.xmlfile=fullfile(path,file);
            end
        end

        function starttime=getRecordStartTime(obj)
            try
                S = external.xml2struct.xml2struct(obj.xmlfile);
                starttime=datetime(S.SETTINGS.INFO.DATE.Text , ...
                    'InputFormat','dd MMM yyyy HH:mm:ss');
                ps=S.SETTINGS.SIGNALCHAIN{1,1}.PROCESSOR;
                for ipro=1:numel(ps)
                    p=ps{ipro};
                    if ismember('PhoStartTimestampPlugin', ...
                            fieldnames(ps{ipro}))
                        starttime1=...
p.PhoStartTimestampPlugin.RecordingStartTimestamp.Attributes.startTime;
                        starttime2=datetime(starttime1 ,'InputFormat', ...
                            'yyyy-MM-dd_HH:mm:ss.SSSSSSS');
                        if starttime.Minute==starttime2.Minute&&...
                                starttime.Year==starttime2.Year...
                                &&starttime.Month==starttime2.Month...
                                &&starttime.Day==starttime2.Day
                            starttime.Second=starttime2.Second;
                            starttime.Second=starttime2.Second;
                        end
                        fprintf(['\t-->\tStart time of the record read by' ...
                            ' milisecond accuracy %.7f.\n'],starttime2.Second);
                    end
                end
            catch ME
                warning('Start time of the record couldn''t be read properly.\n')
                starttime=[];
            end

        end


        function openEphysRecord = load(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            log=logging.Logger.getLogger;

            starttime1=obj.getRecordStartTime();
            fprintf('Start Time in .xml file: %s\n',datestr(starttime1, ...
                'dd-mmm-yyyy HH:MM:SS.FFF'));
            %             file=dir(obj.OEBinFile);
            %             samples=file.bytes/2/header.num_channels;

            datFileSize=obj.calculateDatFileSize;
            [ts,file]=obj.getTimeStamps;
            %                 log.info(num2str(file.bytes))
            %                 log.info(num2str(obj.calculateTimestampsFileSize))
            %                 log.info(num2str(obj.calculateTimestampsFileSize-file.bytes))


            if datFileSize<=obj.getDatFile.bytes
                fprintf('Loading binary file...\n');tic
                D= load_open_ephys_binary(obj.OEBinFile,'continuous',1, ...
                    'mmap','.dat');toc
                log.fine(sprintf('Binary continuous loaded. %s',obj.OEBinFile))
            else
                log.error(sprintf('\n%s\n\t should be --> %d bytes.', ...
                    fullfile(obj.getDatFile.folder,obj.getDatFile.name),datFileSize))
                return
            end
            recLatency=double(ts(1))/D.Header.sample_rate;
            fprintf('First time stamp %.5f s.\n',recLatency)
            [filepath,name,ext] = fileparts(obj.OEBinFile);
            C=split(filepath,filesep);
            rec=C{end};cs=strsplit(rec,'recording');recno=str2double(cs{2});
            if recno==1
                obj.Record1Lantency=seconds(recLatency);
            else
                a=fullfile(filepath,'..','recording1');
                f1=java.io.File(a);
                a1=f1.getCanonicalPath;

                try
                    fileID = fopen(fullfile(char(a1),'sync_messages.txt'), 'r');
                    lines=textscan(fileID, '%s', 'delimiter', '\n');lines=lines{:};
                    fclose(fileID);
                    % Extract information using regular expressions
                    % softwareTime = regexp(lines{1}, ...
                    %     'Software time: (\d+)@(\d+)Hz', 'tokens');
                    % softwareTime=softwareTime{:};
                    processorInfo = regexp(lines{2}, ...
                        ['Id: (\d+) subProcessor: ' ...
                        '(\d+) start time: (\d+)@(\d+)Hz'], 'tokens');
                    processorInfo=processorInfo{:};
                    time=str2double(processorInfo{3});
                    sampleRate=str2double(processorInfo{4});
                    obj.Record1Lantency=seconds(time/sampleRate);
                catch ME
                    log.error([ME.identifier ME.message]);
                    a=fullfile(filepath,'..','recording1LatencyInSec.txt');
                    f1=java.io.File(a);
                    a1=char(f1.getCanonicalPath);
                    try
                        obj.Record1Lantency=seconds(readmatrix(a1));
                    catch ME
                        log.error([ME.identifier ME.message]);
                        est=starttime1+seconds(recLatency);
                        log.error(sprintf(['%s \n\t is not found in the ' ...
                            'location. \n\t provide the difference' ...
                            ' for rec %d, estimation was %s'],a1, recno,est))
                    end
                end
            end
            starttime=starttime1+seconds(recLatency)-obj.Record1Lantency;
            fprintf('Real start time of the record: %s\n',string(starttime));
            hdr=D.Header;
            S = external.xml2struct.xml2struct(obj.xmlfile);
            hdr.SettingsAtXMLFile=S.SETTINGS;


            openEphysRecord.Header=hdr;
            openEphysRecord.Channels=1:hdr.num_channels;
            openEphysRecord.Data=D.Data;

            file=dir(D.Data.Filename);
            samples=file.bytes/2/hdr.num_channels;

            openEphysRecord.TimeInterval=neuro.time.TimeInterval( ...
                starttime,D.Header.sample_rate,samples);
            openEphysRecord.DataFile=D.Data.Filename;
            try
                openEphysRecord.evts= load_open_ephys_binary( ...
                    obj.OEBinFile,'events',1,'mmap','.dat');toc
            catch
                log.warning('No event data.')
            end
            try
                openEphysRecord.spks= load_open_ephys_binary( ...
                    obj.OEBinFile,'spikes',1,'mmap','.dat');toc
            catch
                log.warning('No spike data.')
            end
        end
        function [ts,file]=getTimeStamps(obj)
            %Look for folder
            json=jsondecode(fileread(obj.OEBinFile));
            f=java.io.File(obj.OEBinFile);
            if (~f.isAbsolute())
                f=java.io.File(fullfile(pwd,jsonFile));
            end
            f=java.io.File(f.getParentFile(),fullfile('continuous', ...
                json.continuous.folder_name));
            if(~f.exists())
                error('Data folder not found');
            end
            folder = char(f.getCanonicalPath());
            file=dir(fullfile(folder,'timestamps.npy'));
            try
                ts = readNPY(fullfile(folder,'timestamps.npy'));
            catch
                log=logging.Logger.getLogger;
                try
                    log.error(['\nFile %s \n\tFile size is %d bytes,' ...
                        ' should be %d bytes.\n'],...
                        fullfile(file.folder,file.name), file.bytes, ...
                        obj.calculateTimestampsFileSize);
                catch
                    if isempty(file)
                        log.error('\n No file \n\t%s\n\twill be created.', ...
                            fullfile(folder,'timestamps.npy'));
                    end
                end
                filepath=fileparts(char(f.getParent));
                fileID = fopen(fullfile(filepath,'sync_messages.txt'), 'r');
                lines=textscan(fileID, '%s', 'delimiter', '\n');lines=lines{:};
                fclose(fileID);
                processorInfo = regexp(lines{2}, ...
                    ['Id: (\d+) subProcessor: ' ...
                    '(\d+) start time: (\d+)@(\d+)Hz'], 'tokens');
                processorInfo=processorInfo{:};
                time=str2double(processorInfo{3});

                obj.createTimestamps(fullfile(folder,'timestamps.npy'),time);
                ts = readNPY(fullfile(folder,'timestamps.npy'));
            end
        end
        function [recordLength]=getRecordLength(obj)
            %Look for folder
            json=jsondecode(fileread(obj.OEBinFile));
            recordLength=numel(obj.getTimeStamps)/json.continuous.sample_rate;
        end
        function file=getDatFile(obj)
            %Look for folder
            json=jsondecode(fileread(obj.OEBinFile));
            f=java.io.File(obj.OEBinFile);
            if (~f.isAbsolute())
                f=java.io.File(fullfile(pwd,jsonFile));
            end
            f=java.io.File(f.getParentFile(),fullfile('continuous', ...
                json.continuous.folder_name));
            if(~f.exists())
                error('Data folder not found');
            end
            folder = char(f.getCanonicalPath());
            contFile=fullfile(folder,'continuous.dat');
            file=dir(contFile);
        end
        function fileSize=calculateDatFileSize(obj)
            samplesize=numel(obj.getTimeStamps);
            json=jsondecode(fileread(obj.OEBinFile));
            nchannnels=json.continuous.num_channels;
            fileSize=nchannnels*samplesize*2;
        end
        function filesize=calculateTimestampsFileSize(obj)
            json=jsondecode(fileread(obj.OEBinFile));
            nchannnels=json.continuous.num_channels;
            filesize=obj.getDatFile.bytes/nchannnels/2*8+128;
        end
        function samplesize=calculateTimestampsSampleSize(obj)
            json=jsondecode(fileread(obj.OEBinFile));
            nchannnels=json.continuous.num_channels;
            samplesize=obj.getDatFile.bytes/nchannnels/2;
        end
        function file=createTimestamps(obj,file,startSample)
            samplesize=obj.calculateTimestampsSampleSize;
            arr=zeros(samplesize,1,'int64');
            arr(1:samplesize)=startSample:(startSample+samplesize-1);
            writeNPY(arr,file);
        end
    end
end
