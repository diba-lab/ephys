% [PlaceMap, OccupancyMap] = PFClassic(Pos, SpkCnt, Smooth, nGrid, TopRate)
% Place field calculation "classic style" where a smoothed spike count map
% is divided by a smoothed occupancy map
%
% Pos is a nx2 array giving position in each epoch.  It should be in
% the range 0 to 1.  SpkCnt gives the number of spikes in each epoch.
%
% Smooth is the width of the Gaussian smoother to use (in 0...1 units).
%
% nGrid gives the grid spacing to evaluate on (should be larger than 1/Smooth)
%
% TopRate is for the maximum firing rate on the color map (if you display it)
% if you don't specify this it will be the maximum value
%
% optional output OccupancyMap is a smoothed occupancy map

function [PlaceMap, sTimeSpent] = PF1D(Pos, SpkCnt, Smooth, nGrid, timebinsize)
% 

% when the rat spends less than this many time points near a place,
% start to dim the place field
if nargin<5;
    timebinsize = 0.01;
end

BinThresh = 10; % minimum number of timespent in timebinsize bins, in order to be included
  % in bins.


% integrized Pos (in the range 1...nGrid
iPos = 1+floor(nGrid*Pos/(1+eps));

% make unsmoothed arrays
TimeSpent = full(sparse(iPos(:,1), iPos(:,2), 1, nGrid, nGrid));
nSpikes = full(sparse(iPos(:,1), iPos(:,2), SpkCnt, nGrid, nGrid));

sTimeSpent = full(sparse(iPos(:,1), iPos(:,2), 1, nGrid, nGrid));
snSpikes = full(sparse(iPos(:,1), iPos(:,2), SpkCnt, nGrid, nGrid));

scalemap = 1./(1+timebinsize*BinThresh./(sTimeSpent*timebinsize+eps));

PlaceMap = snSpikes./(sTimeSpent+eps);

PlaceMap = PlaceMap.*scalemap/timebinsize;

% there is some question here as what is the best way to convert a 2D
% placemap into a 1D placemap.  My approach is to calculate the placefield
% in the 2D environment, and then take the maximum projection onto the
% x-axis.  Smoothing is only done at the very end..

PlaceMap = max(PlaceMap,[],2);
sTimeSpent = sum(sTimeSpent,2);

smoothwin = ones(1,round(nGrid/25)); 
smoothwin = smoothwin/sum(smoothwin);

PlaceMap = filtfilt(smoothwin,1,PlaceMap);