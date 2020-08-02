classdef OpenEphysRecordsCombined < Timelined
    %OPENEPHYSRECORDSCOMBINED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access= private)
        OpenEphysRecords
        Animal
        Probe
        Day
        RoomInfo
    end
    
    %% Constructor
    methods (Access=public)
        function newobj = OpenEphysRecordsCombined(varargin)
            %OPENEPHYSRECORDSCOMBINED Construct an instance of this class
            openEphysRecords=CellArrayList();
            for iArgIn=1:nargin
                theOpenEphysRecord=varargin{iArgIn};
                assert(isa(theOpenEphysRecord,'OpenEphysRecord'));
                openEphysRecords.add(theOpenEphysRecord);
                fprintf('Record addded:\n%s\n', theOpenEphysRecord.getFile);
            end
            newobj.OpenEphysRecords=openEphysRecords;
        end
    end
    methods
        
        function obj=plus(obj,varargin)
            for iArgIn=1:(nargin-1)
                theOpenEphysRecord=varargin{iArgIn};
                assert(isa(theOpenEphysRecord,'OpenEphysRecord'));
                obj.OpenEphysRecords.add(theOpenEphysRecord);
                fprintf('Record addded:\n%s\n', theOpenEphysRecord.getFile);
            end
        end
        
        function obj = removeAnOpenEphysRecord(obj,theNumberOfTheRecord)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.OpenEphysRecords(theNumberOfTheRecord)=[];
        end
        
        
        function print(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            iter=obj.getIterator();
            while(iter.hasNext())
                anOpenEphysRecord=iter.next();
                
            end
        end
        function saveChannels(obj,channels)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            iter=obj.getIterator();
            while(iter.hasNext())
                anOpenEphysRecord=iter.next();
                anOpenEphysRecord.saveChannels(channels);
            end
        end
        function fileout=mergeBlocksOfChannels(obj,channels,path)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            iter=obj.getIterator();
            first=true;
            oers=obj.getOpenEphysRecords;
            strt =oers.get(1).getRecordStartTime;
            end1 =oers.get(oers.length).getRecordEndTime;
            fname=sprintf('merged_%s__%s_%s',datestr(strt,'yyyy-mmm-dd'),...
                datestr(strt,'HH-MM-SS'),datestr(end1,'HH-MM-SS'));
            fileout=fullfile(path, fname,[fname '.lfp']);
            
            [folder,fname,ext]=fileparts(fileout);
            ticd=obj.getTimeIntervalCombined;
            if ~isfolder(folder), mkdir(folder), end
            save(fullfile(folder,[fname '.TimeIntervalCombined.mat']),'ticd');
            probe=obj.getProbe;
            probe=probe.setActiveChannels(channels);
            while(iter.hasNext())
                anOpenEphysRecord=iter.next();
                fileIn=anOpenEphysRecord.saveChannels(channels);
                if first
                    fprintf('\nFile\t %s is being added\n\tin file  %s\n',fileIn,fileout)
                    tic
                    system(sprintf('cat %s>%s',...
                        fileIn,fileout),'-echo');toc
                    first=false;
                else
                    fprintf('\nFile\t %s is being added\n\tin file  %s\n',fileIn,fileout)
                    tic
                    system(sprintf('cat %s>>%s',...
                        fileIn,fileout),'-echo');toc
                    fprintf('Done.\n')
                    
                end
                delete(fileIn);
            end
            probe=probe.renameChannelsByOrder(channels);
            probe.saveProbeTable( fullfile(folder,[fname '.Probe.mat']));
            ticd=obj.getTimeIntervalCombined;
            probe.createXMLFile(fullfile(folder,[fname '.xml']),ticd.getSampleRate)
        end
    end
    
    %% PLOTS
    methods (Access=public)
        function p1=plotTimelineCombined(obj)
            tls=obj.getTimeline();
            timeLineCombined=[];
            if iscell(tls)
                nTimeLines=numel(tls);
            else
                nTimeLines=1;
            end
            for iTimeLine=1:nTimeLines
                if iscell(tls)
                    aTimeLine=tls{iTimeLine};
                else
                    aTimeLine=tls;
                end
                timeLineCombined=[timeLineCombined aTimeLine];
                obj.plotTimeline(timeLineCombined);
            end
        end
    end
    %% GETTERS AND SETTERS
    methods (Access=public)
        function tls=getTimeline(obj)
            iter=obj.getIterator();
            tls=[];
            i=1;
            while(iter.hasNext)
                anOpenEphysRecord=iter.next();
                tl=anOpenEphysRecord.getTimeline();
                tls{i}=tl;i=i+1;
            end
        end
        function timeIntervalCombined=getTimeIntervalCombined(obj)
            iter=obj.getIterator();
            tls=[];
            i=1;
            timeIntervalCombined=TimeIntervalCombined;
            while(iter.hasNext)
                anOpenEphysRecord=iter.next();
                timeIntervalCombined=timeIntervalCombined+anOpenEphysRecord.getTimeInterval();
            end
        end
        function evts=getEvents(obj)
            evts=obj;
        end
        function oerc=addEvents(obj,evts)
            iter=obj.getIterator;
            
            while iter.hasNext
                oer=iter.next;
                oer=oer.addEvents(evts);
                if exist('oerc','var')
                    oerc=oerc+oer;
                else
                    oerc=oer;
                end
            end
            oerc.Probe=obj.Probe;
            oerc.Animal=obj.Animal;
            oerc.RoomInfo=obj.RoomInfo;
            oerc.Day=obj.Day;
        end
        
        function oers=getOpenEphysRecords(obj)
            oers=obj.OpenEphysRecords;
        end
        
        function [Sections return1]=getTimeWindow(obj, timeWindow)
            iter=obj.getIterator;
            ioer=1;
            Sections=[];
            while iter.hasNext
                oer=iter.next;
                oerRange=[oer.getRecordStartTime oer.getRecordEndTime];
                isTimeWindowsStartInThis(ioer)=(timeWindow(1)>=...
                    oerRange(1))&...
                    (timeWindow(1)<=oerRange(2));
                isTimeWindowsEndInThis(ioer)=(timeWindow(2)>=oerRange(1))&...
                    (timeWindow(2)<=oerRange(2));
                ioer=ioer+1;
            end
            oers=obj.OpenEphysRecords;
            if find(isTimeWindowsStartInThis)==find(isTimeWindowsEndInThis)
                startingOer=oers.get(find(isTimeWindowsStartInThis));
                Sections{1}=startingOer.getTimeWindow(timeWindow);
                return1=startingOer;
            else
                for ioer=find(isTimeWindowsStartInThis):...
                        find(isTimeWindowsEndInThis)
                    theOer(ioer)=oers.get(ioer);
                    Sections{ioer}=theOer(ioer).getTimeWindow(timeWindow);
                end
                return1=theOer(find(isTimeWindowsStartInThis));
            end
        end
        
        function obj=getDownSampled(obj,newRate,activeWorkspaceFolder)
            iter=obj.getIterator();
            anOpenEphysRecord=iter.next();
            openEphysRecords=...
                anOpenEphysRecord.getDownSampled(newRate,activeWorkspaceFolder);
            
            while(iter.hasNext)
                anOpenEphysRecord=iter.next();
                openEphysRecords=openEphysRecords+...
                    anOpenEphysRecord.getDownSampled(...
                    newRate,activeWorkspaceFolder);
            end
            obj=openEphysRecords;
        end
        function obj=runStateDetection(obj,varargin)
            iter=obj.getIterator();
            while(iter.hasNext)
                anOpenEphysRecord=iter.next();
                sessionStruct=BuzcodeFactory.getBuzcode(anOpenEphysRecord);
                stateDetectionBuzcode=StateDetectionBuzcode();
                stateDetectionBuzcode=...
                    stateDetectionBuzcode.setBuzcodeStructer(sessionStruct);
                stateDetectionData=stateDetectionBuzcode.getStates;
                %                 stateDetectionData.openStateEditor
            end
        end
        
    end
    %% Public Functions
    methods (Access=public)
        function iterator=getIterator(obj)
            iterator=obj.OpenEphysRecords.createIterator;
        end
        function obj=setProbe(obj,Probe)
            obj.Probe=Probe;
        end
        function probe=getProbe(obj)
            probe=obj.Probe;
        end
    end
    %% Private Functions
    methods (Access=private)
        
    end
end