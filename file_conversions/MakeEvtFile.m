function MakeEvtFile(Input,varargin)
% 
%function MakeEvtFile(Input,OutFileName,Labels,SampleRate,Overwrite)
%Input - one column or two column vector of times 
% Labels - string, cell array of strings or vector of label indexes (e.g.
% clu file)
% Overwrite  - 1, if 0 - append. 
% [OutFileName,Labels,SampleRate,Overwrite] = DefaultArgs(varargin,{[],[],32552,1});

ip = inputParser;
ip.addRequired('Input', @(a) isnumeric(a));
ip.addOptional('OutFileName', [], @ischar);
ip.addOptional('Labels', [], @(a) iscell(a) || isnumeric(a));
ip.addOptional('SampleRate', [], @isnumeric);
ip.addOptional('Overwrite', 1, @(a) a == 0 || a == 1);
ip.parse(Input, varargin{:});
OutFileName = ip.Results.OutFileName;
Labels = ip.Results.Labels;
SampleRate = ip.Results.SampleRate;
Overwrite = ip.Results.Overwrite;


if isstr(Input)&isempty(OutFileName)
	OutFileName = [Input '.evt'];
end

if isstr(Input)
	Input = load(Input);
end

if isempty(Labels) %default 
    % no label - use '1'
    Labels = '1';

elseif isstr(Labels) & FileExists(Labels)% if Labels is a file name 
    
	fl= FileLines(Labels);
	if fl == size(Input,1) % if a file of right length
		Labels = load(Labels);
        
	elseif  fl==size(Input,1)+1 % in case it is clu file
		Labels = load(Labels);
		Labels = Labels(2:end);
    else
        error('size of Labels file doesn''t match the input size');
        
	end
end

if size(Input,2)>1
    if length(Labels)~=size(Input,2)
        error('labels length doesn''t match the number of columns');
    else
        if iscell(Labels)
            Labels = reshape(repmat(Labels(:)',size(Input,1),1)',[],1);
        else
            Labels = reshape(repmat(Labels(:)',size(Input,1),1)',[],1);
        end
    end
	Input = reshape(Input',[],1);
end

if isstr(Labels) | iscell(Labels) |ischar(Labels)
	fid = fopen(OutFileName,'w');
	nTrig = length(Input);
	
	if isstr(Labels) 
		for i=1:nTrig
			fprintf(fid,'%f %s\n',(Input(i)*1000/SampleRate),Labels);
		end
	elseif ischar(Labels)
		for i=1:nTrig
			fprintf(fid,'%f %s\n',(Input(i)*1000/SampleRate),Labels(i,:));
		end
    elseif iscell(Labels)
		for i=1:nTrig
			fprintf(fid,'%f %s\n',(Input(i)*1000/SampleRate),Labels{i});
		end
	end
	fclose(fid);
else
 	Mat = [Input*1000/SampleRate Labels];

    msave(OutFileName,Mat);
	
end

