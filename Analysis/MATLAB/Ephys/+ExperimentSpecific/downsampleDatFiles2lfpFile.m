sdl=SDLoader.instance;
FileList = dir(fullfile('/data2/umich/ephys/', '**', '*.oebin'));
for ifile=62:numel(FileList)
    try
    thefile=FileList(ifile);
    oer=sdl.getNewOpenEphysRecord(fullfile(thefile.folder,thefile.name));
    oer_s=oer.getDownSampled(1250);
    catch
        fprintf('error')
    end
end
