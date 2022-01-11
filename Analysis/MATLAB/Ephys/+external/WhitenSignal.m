%function [y, ARmodel] = WhitenSignal(x, window,CommonAR,ARmodel)
% whitens the signal 
% if window specified will recompute the model in each window of that size
% if CommonAR is set to 1, then will use model from first channel for all
% if ARmodel is specified - use it, not compute fromthe data
% output optionaly the ARmodel for use on the other data to be on the same scale
% seems that phase is shifted by Filter0 - check .. otherwise reprogram to
% filter with filtfilt , instead.
function [y, A] = WhitenSignal(x,varargin)

[window,CommonAR, ARmodel] = external.DefaultArgs(varargin,{[],0,[]});
Trans = 1;
if size(x,1)<size(x,2)
    x = x';
    Transf =1;
end
[nT nCh]  = size(x);
y = zeros(nT,nCh);
if isempty(window)
    seg = [1 nT];
    nwin=1;
else
    nwin = floor(nT/window);
    seg = repmat([1 window],nwin,1)+repmat([0:nwin-1]'*window,1,2);
    if nwin*window<nT
        seg(end,2) =nT;
    end   
end

for j=1:nwin
    if ~isempty(ARmodel)
    A = ARmodel;
        for i=1:nCh
	    y(seg(j,1):seg(j,2),i) = external.Filter0([1 -A], x(seg(j,1):seg(j,2),i));
        end
    else    
	if CommonAR 
		for i=1:nCh
		if  j==1
			[w A] = external.arfit(x(seg(j,1):seg(j,2),i),2,2);
		end
		y(seg(j,1):seg(j,2),i) = external.Filter0([1 -A], x(seg(j,1):seg(j,2),i));
		end
	else
		for i=1:nCh
		[w A] = external.arfit(x(seg(j,1):seg(j,2),i),2,2);
		y(seg(j,1):seg(j,2),i) = external.Filter0([1 -A], x(seg(j,1):seg(j,2),i));
		end
	end
    end
end

if Trans
    y =y';
end