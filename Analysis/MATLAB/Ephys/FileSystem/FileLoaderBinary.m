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
            
            listing=dir(fullfile(filepath,'..','..','*.xml'));
            if numel(listing)>1
                listing1=dir(fullfile(filepath,'..'));
                experimentno=str2double(listing1(1).folder(end));
                xmlfile=fullfile(listing(1).folder,sprintf('settings_%d.xml',experimentno));
            else
                xmlfile=fullfile(listing.folder,listing.name);
            end
            obj.xmlfile=xmlfile;
        end
        
        function openEphysRecord = load(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            S = xml2struct(obj.xmlfile);
            starttime1=datetime(S.SETTINGS.INFO.DATE.Text ,'InputFormat','dd MMM yyyy HH:mm:ss');
            
            D= load_open_ephys_binary(obj.OEBinFile,'continuous',1,'mmap','.dat');
            recLatency=double(D.Timestamps(1))/D.Header.sample_rate;
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
            hdr=D.Header;
            hdr.SettingsAtXMLFile=S.SETTINGS;
            
            
            openEphysRecord.Header=hdr;
            openEphysRecord.Data=D.Data;
            D.Timestamps=D.Timestamps-D.Timestamps(1);
            tst=double(D.Timestamps)/D.Header.sample_rate;
            
            ts=timeseries(nan(numel(tst),1),tst);
            ts.TimeInfo.Format='dd-mmm-yyyy HH:MM:SS.FFF';
            ts.TimeInfo.StartDate=starttime;
            openEphysRecord.Timestamps=ts;
            openEphysRecord.DataFile=D.Data.Filename;
        end
    end
end
