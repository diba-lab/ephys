classdef OpenEphysRecordHeader
    %OPENEPH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        SampleRate
        ChannelsTable
        ActiveChannels
        SettingsXMLinfo
        DataFile
    end
    
    methods
        function obj = OpenEphysRecordHeader(h)
            %OPENEPH Construct an instance of this class
            %   Detailed explanation goes here
            try
                try
                    obj.SampleRate=h.sample_rate;
                catch
                    obj.SampleRate=h.samplingFrequency;

                end
                obj.ChannelsTable=h.channels;
                obj.ActiveChannels=true(1,numel(obj.ChannelsTable));
            catch
                obj.SampleRate=h.sampleRate;
                obj.ChannelsTable=GarbageFactory.getChannelsTable;
                chans=h.SettingsAtXMLFile.SIGNALCHAIN.PROCESSOR{1, 1}.CHANNEL_INFO.CHANNEL;
                chans=cell2mat(chans);
                att={chans.Attributes};att=cell2mat(att);
                names={att.name};
                obj.ActiveChannels=ismember({obj.ChannelsTable.channel_name},names);
            end
            try
                obj.SettingsXMLinfo=h.SettingsAtXMLFile;
            catch
                warning('SettingsAtXMLFile couldn''t be found.\n')
            end
        end
    end
    methods
        function out = getSampleRate(obj)
            out=obj.SampleRate;
        end
        function out = getDataFile(obj)
            out=obj.DataFile;
        end
        function out = getChannels(obj)
            t1={obj.ChannelsTable.channel_name};
            out=t1(obj.ActiveChannels);
        end
        function obj = setSampleRate(obj,sr)
            obj.SampleRate=sr;
        end
        function obj = setChannels(obj,new)
            [Lia,~] = ismember({obj.ChannelsTable.channel_name},new);
            obj.ActiveChannels=Lia;
        end
        function obj = setDataFile(obj,filename)
            obj.DataFile=filename;
        end
        function out = getChannelsTable(obj)
            out=obj.ChannelsTable;
        end
    end
    
end

