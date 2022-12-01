ol=optiTrack.OptiLoader.instance('/data1/EphysAnalysis/Position/B2/2022-05-25/Position/csv');
ofc=ol.loadFile;
f=figure;ofc.plotTimeline;pause(3);close(f);
try
    [files, path] = uigetfile({'*.xml','Parameters (*.xml)'},...
        'Select the xml holds scale and  file *.xml file.',...
        obj.defpath,'MultiSelect', 'off');
    s=readstruct(fullfile(path,files));
catch
end

pd=ofc.getMergedPositionData;
pd.source=path;
pd.saveInPlainFormat(path);