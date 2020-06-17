function [xx xi yi] = NearestNeighbour(x,y,varargin)
%function [xx xi yi] = NearestNeighbour(x,y,side, maxdist)
%look for the closest neighbours: value (xx) and index (xi) in x
% of every element of y from the side ('left','right','both')
% within maxdist (in same units as x and y)
% returns xx - values of x which conform criteria, xi = indices of those
% yi - indices of y which have neighbours that conform criteria
%..maybe already exists but couldn't find
[side,maxdist] = DefaultArgs(varargin,{'both',inf});

nx = length(x); ny=length(y);
x=x(:); y=y(:);
[y yorder] = sort(y);
%[x xorder] = sort(x);

z = [-inf; x; y; inf];
[s si] = sort(z);

yloc = (si>nx+1&si<length(z));
%now have to figure out if left or right is closer for each y point
xind = find(~yloc);
leftxindeces = cumsum(~yloc); 
leftxind = xind(leftxindeces(yloc));%this is index within s 
leftx = s(leftxind);

%same for the right - only need to flip the vector upside down
rightxindeces = cumsum(flipud(~yloc));
rightxind = xind(flipud(length(xind)-rightxindeces(flipud(yloc))+1)); 
rightx = s(rightxind);

xi = NaN*zeros(size(y));
xx = NaN*zeros(size(y));

switch side
    case 'both'
        
        %now compare left and right and get the minimal
        [lrdist lr] = min([abs(leftx-y), abs(rightx-y)],[],2);

        lwins=find(lr==1 & lr<maxdist);
        xi(lwins) = si(leftxind(lwins))-1;

        rwins=find(lr==2 & lr<maxdist);
        xi(rwins) = si(rightxind(rwins))-1;

        xx = x(xi);

    case 'left'
        closepts = (y-leftx)<maxdist;
        xx(closepts) = leftx(closepts);
        xi(closepts) = si(leftxind(closepts))-1;

    case 'right'
        closepts = (rightx-y)<maxdist;
        xx(closepts) = rightx(closepts);
        xi(closepts) = si(rightxind(closepts))-1;

end
    
%reorder to original y order
xx = xx(yorder);
xi = xi(yorder);
xx =xx(:);
xi=xi(:);
nani = isinf(abs(xx)) | isnan(xx);
xx(nani)=[];
xi(nani)=[];
yi = find(~nani);

% x'
% y(yorder)'
% xx'
% xi'
% yi'