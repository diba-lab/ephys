classdef ChannelFactory
    %CHANNELFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        BaseFolder
        sdd
        ctd
    end
    
    methods
        function obj = ChannelFactory(baseFolder)
            %CHANNELFACTORY Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                baseFolder (1,1) {mustBeFolder}
            end
            obj.BaseFolder=baseFolder;
            obj.sdd=StateDetectionData(baseFolder);
            obj.ctd=ChannelTimeData(baseFolder);
        end
        
        function ch = getChannel(obj,channelName)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            arguments
                obj ChannelFactory
                channelName {mustBeMember(channelName,{'EMG','Theta',...
                    'SWS','StateSeries'})}
            end
            switch channelName
                case 'EMG'
                    ch=obj.sdd.getEMG;
                case 'Theta'
                    thId=obj.sdd.getThetaChannelID;
                    ch=obj.ctd.getChannel(thId);
                case 'SWS'
                    SWSId=obj.sdd.getSWChannelID;
                    ch=obj.ctd.getChannel(SWSId);
                case 'StateSeries'
                    thId=obj.sdd;
                    ch=obj.ctd.getChannel(thId);
            end
        end
        function ch=getChannelByNumber(obj, channelNumber)
            arguments
                obj ChannelFactory
                channelNumber {mustBeNumeric}
            end
            ch=obj.ctd.getChannel(channelNumber);
        end
    end
    methods (Access=private)
        function list=getChannelNames(obj)
            list=obj;
        end
    end
end