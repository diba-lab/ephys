function D=load_binary(lfpFile)
contFile=lfpFile;
file=dir(contFile);
samples=file.bytes/2/header.num_channels;
D.Data=memmapfile(contFile,'Format',{'int16' [header.num_channels samples] 'mapped'});
end