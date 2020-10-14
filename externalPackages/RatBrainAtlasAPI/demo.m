ml = 1.3;
ap = -3.3;
dv = 7.5;

S = ratBrainAtlas(ml,ap,dv);
figure;imshow(S.coronal.image);
