classdef SettingsFile
    %SETTINGSFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        xmlData
    end
    
    methods
        function obj = SettingsFile(xmlFile)
            obj.xmlData = xmlread(xmlFile);
        end

        function [] = createProbeFile(obj,outputFile)
            
            % Open a file to write the output
            if ~exist("outputFile","var")
                outputFile = 'Probe.csv';
            end
            fid = fopen(outputFile, 'w');

            % Write the header
            fprintf(fid, 'ChannelNumberComingOutFromProbe,X,Y,Z,ShankNumber,ChannelNumberComingOutPreAmp,isActive\n');

            % Extract channel information from the CUSTOM_PARAMETERS section
            processors = obj.xmlData.getElementsByTagName('PROCESSOR');
            for i = 0:processors.getLength-1
                processor = processors.item(i);
                if strcmp(char(processor.getAttribute('name')), 'Channel Map')
                    customParams = processor.getElementsByTagName('CUSTOM_PARAMETERS').item(0);
                    stream = customParams.getElementsByTagName('STREAM').item(0);
                    channels = stream.getElementsByTagName('CH');
                    for j = 0:channels.getLength-1
                        channel = channels.item(j);
                        index = str2double(channel.getAttribute('index'));
                        isActive = str2double(channel.getAttribute('enabled'));
                        x = 0; % Default value for X
                        y = 0; % Default value for Y
                        z = 0; % Default value for Z
                        shankNumber = 0; % Default value for ShankNumber
                        channelNumberPreAmp = j + 1; % Sequential number starting from 1

                        % Write the channel information to the file
                        fprintf(fid, '%d,%d,%d,%d,%d,%d,%d\n', index, x, y, z, shankNumber, channelNumberPreAmp, isActive);
                    end
                    break;
                end
            end

            % Close the file
            fclose(fid);

        end
    end
end

