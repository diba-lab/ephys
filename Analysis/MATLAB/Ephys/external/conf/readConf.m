function configuration = readConf(configfile)
% READCONF reads configuration file. 
%
% The value of boolean parameters can be tested with 
%    exist(parameter,'var')
 
if nargin<1, 
   configfile = 'q.conf';
end;
 
fid = fopen(configfile); 
if fid<0, error('cannot open file %s\n',a); end; 
 
while ~feof(fid)
    line = strtrim(fgetl(fid));
    if isempty(line) || all(isspace(line)) || strncmp(line,'#',1) || strncmp(line,';',1) || strncmp(line,'%',1),
	; % no operation 
    else 
	[var,tok] = strtok(line,{' ',':','=',char(9)});
	var = lower(var); 
	if any(tok==','),
		k = 1; 
		while (1)
			[val, tok]=strtok(tok,{',',':','=',char(9)});
			configuration.(var){k} = strtrim(val);  	% return value of function 
			eval(sprintf('%s{%i}=''%s'';',var,k,strtrim(val)));  % stores variable in local workspace
		if isempty(tok), break; end;
			k=k+1;
		end;
	else 
		tok = strtrim(tok);
		configuration.(var) = tok;		% return value of function
		eval(sprintf('%s=''%s''; ',var,tok));  % stores variable in local workspace
	end;
    end;
end; 
fclose(fid);
%whos,     % shows the parameter in the local workspace 