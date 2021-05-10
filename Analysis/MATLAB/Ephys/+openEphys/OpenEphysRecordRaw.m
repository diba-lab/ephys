classdef OpenEphysRecordRaw < openEphys.OpenEphysRecord
    %OPENEPHYSRECORD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        
    end
    
    methods (Access=public)
        function obj = OpenEphysRecordRaw(filename)
            obj = obj@openEphys.OpenEphysRecord(filename);
            fileLoaderMethod=obj.getFileLoaderMethod;
            
            oeProperties = fileLoaderMethod.load();
            obj = obj.setData(oeProperties.Data);
            obj = obj.setTimeInterval(oeProperties.TimeInterval);
            obj = obj.setChannels(oeProperties.Channels);
        end
        %% Functions
        
        function obj=keepOnlyTheseAndRemoveTheRest(obj,channels,timewindows)
            flm=obj.getData;
            [path,filename,ext]=fileparts(flm.Filename);
            ind=obj.getChannelIndexes(channels);
            ts=obj.getTimestamps;
            
            for iwin=1:size(timewindows,1)
                timewindowraw=timewindows(iwin,:);
                timewindow=timewindowraw/obj.getSampleRate;
                datasection=flm.Data.mapped(ind,timewindowraw(1):timewindowraw(2));
                tssection=ts.gettsbetweenevents(...
                    tsdata.event('start',timewindow(1)),...
                    tsdata.event('end',timewindow(2)) );
                if ~exist('tssections','var')
                    tssections=tssection;
                else
                    tssections=tssections.append(tssection);
                end
                fname=fullfile(path,[filename,'.cleaned',ext]);
                fw=FileWriter.instance(fname);
                fw.addSection(datasection);
            end
            obj=obj.setTimestamps(tssections);
            tssections.Data=1;
            p1=tssections.plot;
            p1.LineStyle='none';
            p1.Marker='+';
            fw.close;
        end
    end
    
    methods (Access=private)
    end
end