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
                warning(sprintf('Record addded:\n%s\n', theOpenEphysRecord.getFile))
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
                warning(sprintf('Record addded:\n%s\n', theOpenEphysRecord.getFile))
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
        function mergeBlocksOfChannels(obj,channels,path)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            iter=obj.getIterator();
            first=true
            while(iter.hasNext())
                anOpenEphysRecord=iter.next();
                fileIn=anOpenEphysRecord.saveChannels(channels);
                [p,name,ext]=fileparts(fileIn);
                fileout=fullfile(path,[name ext]);
                if first
                    fprintf('File\t %s is being added in\nfile\t %s\n',fileIn,fileout)
                    tic
                    [status,cmdout]=system(sprintf('cat %s>%s',...
                        fileIn,fileout),'-echo');toc
                    first=false;
                else
                    fprintf('File\t %s is being added in\nfile\t %s\n',fileIn,fileout)
                    tic
                    [status,cmdout]=system(sprintf('cat %s>>%s',...
                        fileIn,fileout),'-echo');toc
                    fprintf('File\t %s id added in\nfile\t %s',fileIn,fileout)
                    
                end
                
            end
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
    %% Private Functions
    methods (Access=public)
        function iterator=getIterator(obj)
            iterator=obj.OpenEphysRecords.createIterator;
        end
    end
end