function S = ratBrainAtlas(ml,ap,dv)
    url  = atlasUrl(ml,ap,dv);
    try
        S = webread(url);
    catch ME
        error('Unable to complete web request.');
        S = [];
    end
    S = jsondecode(S);
    S.coronal.image = webread(S.coronal.image_url,'ContentType','image');
    S.sagittal.image = webread(S.sagittal.image_url,'ContentType','image');
    S.horizontal.image = webread(S.horizontal.image_url,'ContentType','image');
    % supply TRUE to make marking
    if license('test', 'image_toolbox')
        S.coronal.image_marked = insertShape(S.coronal.image,'FilledCircle',[S.coronal.left S.coronal.top 10],'Color','r','Opacity',1);
        S.sagittal.image_marked = insertShape(S.sagittal.image,'FilledCircle',[S.sagittal.left S.sagittal.top 10],'Color','r','Opacity',1);
        S.horizontal.image_marked = insertShape(S.horizontal.image,'FilledCircle',[S.horizontal.left S.horizontal.top 10],'Color','r','Opacity',1);
    end
end


function url  = atlasUrl(ml,ap,dv)
    api = 'http://labs.gaidi.ca/rat-brain-atlas/api.php?';
    url = [api 'ml=' num2str(ml) '&ap=' num2str(ap) '&dv=' num2str(dv)];
end