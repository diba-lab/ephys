classdef BinaryDataFile
    %BINARYDATAFILE This class is used for loading Binary data files
    %as in OpenEpyhs *.dat and *.lfp,*.eeg
    %   Detailed explanation goes here
    
    properties
        FileName
        SampleRate
        NumberOfChannels
    end
    
    methods
        function obj = BinaryDataFile(filename,sr,nch)
            %BINARYDATAFILE Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                filename String
                sr (1,1) int16
                nch (1,1) int16
            end
            obj.FileName=filename;
            obj.SampleRate=sr;
            obj.NumberOfChannels=nch;
        end
        
        function combined = concatenate(obj,binaryDataFile)
            %CONCATENATE combine the files into one if they are in the same
            %format
            %   number of files allowed yet to be decided based on
            %   capabilities of lower level functions.
            arguments
                obj
                binaryDataFile neuro.basic.BinaryDataFile
            end
            % check if number of channels and sample rates are the same
            % combine them here either using NeuroSuite functions or Matlab
            % functions
        end

    end
end

