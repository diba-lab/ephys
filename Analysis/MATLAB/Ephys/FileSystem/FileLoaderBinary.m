classdef FileLoaderBinary < FileLoaderMethod
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
                    xmlfile=fullfile(listing(1).folder,sprintf('settings_%d.xml',experimentno));
                else
                    xmlfile=fullfile(listing.folder,listing.name);
                end
                obj.xmlfile=xmlfile;
            catch
                warning('Settings .XML file couldn''t be found in folder\n%s\nIt should be in ../.. relative to .oebin file\n',listing(1).folder);
                [file,path] = uigetfile('*.xml');
                obj.xmlfile=fullfile(path,file);
            end
        end
        
        function starttime=getRecordStartTime(obj)
            try
                S = xml2struct(obj.xmlfile);
                starttime=datetime(S.SETTINGS.INFO.DATE.Text ,'InputFormat','dd MMM yyyy HH:mm:ss');
            catch
                warning('Start time of the record couldn''t be read properly.\n')
                starttime=[];
            end
            
        end
        
        
        function openEphysRecord = load(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            starttime1=obj.getRecordStartTime();
            fprintf('Start Time in .xml file: %s\n',datestr(starttime1));
            fprintf('Loading binary file...\n');tic
            D= load_open_ephys_binary(obj.OEBinFile,'continuous',1,'mmap','.dat');toc
            recLatency=double(D.Timestamps(1))/D.Header.sample_rate;
            fprintf('First time stamp (in s.): %.5f\n',recLatency)
            [filepath,name,ext] = fileparts(obj.OEBinFile);
            C=strsplit(filepath,filesep);
            rec=C{end};recno=str2double(rec(10:end));
            if recno==1
                obj.Record1Lantency=seconds(recLatency);
            else
                filepath(end)='1';
                T=readtable(fullfile(filepath,'sync_messages.txt'));
                c=table2cell(T);txt=c{1};tokens=tokenize(txt,' @Hz');
                time=str2double(tokens{end-1-2});sampleRate=str2double(tokens{end-2});
                obj.Record1Lantency=seconds(time/sampleRate);
            end
            starttime=starttime1+seconds(recLatency)-obj.Record1Lantency;
            fprintf('Real start time of the record: %s\n',datestr(starttime));
            hdr=D.Header;
            S = xml2struct(obj.xmlfile);
            hdr.SettingsAtXMLFile=S.SETTINGS;
            
            
            openEphysRecord.Header=hdr;
            openEphysRecord.Data=D.Data;

            file=dir(D.Data.Filename);
            samples=file.bytes/2/hdr.num_channels;
            tst=(double(1:samples)-1)/D.Header.sample_rate;
            ts=timeseries(nan(numel(tst),1),tst);
            ts.TimeInfo.Format='dd-mmm-yyyy HH:MM:SS.FFF';
            ts.TimeInfo.StartDate=starttime;
            
            openEphysRecord.Timestamps=ts;
            openEphysRecord.DataFile=D.Data.Filename;
        end
    end
end
