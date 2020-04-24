function [Scomb_bot, Scomb_top] = plot_implant_coords(AP, ML, DV, angle, varargin)
% function [Scomb_bot, Scomb_top] = plot_implant_coords(AP, ML, DV, angle, varargin)
%
% Plots coronal sections showing each edge at center of silicon probe
% centered on AP/ML input coordinates at driven to DV below the surface of
% the brain. Requires downloading Mat Gaidica's Brain Atlas API at
% https://github.com/mattgaidica/RatBrainAtlasAPI.
% 
% Assumes vertical implant as of 2020MAR10. NOTE that inputs for
% AP/ML/DV are in mm but all other distances are in microns!
%
% INPUTS
% AP/ML/DV: implant coordinates in mm. DV is measured from surface of the brain
% assuming a skull thickness of approximate 600um (can specify below).
%
% angle: rotation about DV axis for implant in degrees. 0 = aligned with ML.
%
% varargins (name, value):
%   span: lateral span of silicon probe shanks in microns. Default: 750.
%
%   skull_t: skull thickness in microns. Default: 600.
%
%   vert_span: vertical span (microns) from top to bottom electrode on a shank.
%   Provides another plot if non-NaN. Default: NaN.
%
%   OUTPUTS: Scomb: data structure with locations of probe marked in red
%   for top (and bottom if vert_span is defined).

%% Parse inputs
ip = inputParser;
ip.addRequired('AP', @isnumeric);
ip.addRequired('ML', @isnumeric);
ip.addRequired('DV', @isnumeric);
ip.addRequired('angle', @isnumeric);
ip.addParameter('span', 750, @(a) isnumeric(a) && a > 0);
ip.addParameter('skull_t', 500, @(a) isnumeric(a) && a > 0); % In reality it's more like 600um, but this seems to give more accurate landmarks for me...
ip.addParameter('vert_span', nan, @(a) isnan(a) || (isnumeric(a) && a > 0));
ip.addParameter('plot_radius', 5, @(a) isnumeric(a) && a > 0);
ip.parse(AP, ML, DV, angle, varargin{:});
span = ip.Results.span;
skull_t = ip.Results.skull_t;
vert_span = ip.Results.vert_span;
plot_radius = ip.Results.plot_radius;

%% Calculate coordinates [AP, ML, DV]

span_mm = span/1000; % convert to mm
skull_mm = skull_t/1000;
vert_mm = vert_span/1000;

center_bot = [AP, ML, DV+skull_mm];

left_bot = [AP - sind(angle)*span_mm/2, ML - cosd(angle)*span_mm/2, DV+skull_mm];

right_bot = [AP + sind(angle)*span_mm/2, ML + cosd(angle)*span_mm/2, DV+skull_mm];

if ~isnan(vert_span)
   center_top = center_bot -  [ 0 0 vert_mm];
   left_top = left_bot - [ 0 0 vert_mm];
   right_top = right_bot - [ 0 0 vert_mm];
end

%% Plot targets
Scomb_bot = plot_targets(left_bot, center_bot, right_bot, plot_radius);
title(subplot(2,3,2), ['Bottom Electrode Locations ' num2str(angle) ' degrees'])

if ~isnan(vert_span)
    Scomb_top = plot_targets(left_top, center_top, right_top, plot_radius);
    title(subplot(2,3,2), ['Top Electrode Locations ' num2str(angle) ' degrees'])
else
    Scomb_top = nan';
end


end

%% Combine and plot
function [Scomb] = plot_targets(left_coords, center_coords, right_coords, ...
    radius)

% Get coords
Sleft = ratBrainAtlas(left_coords(2), left_coords(1), left_coords(3));
Scenter = ratBrainAtlas(center_coords(2), center_coords(1), center_coords(3));
Sright = ratBrainAtlas(right_coords(2), right_coords(1), right_coords(3));


% Consolidate into one structure for plotting ease
Scomb = consolidate(Sleft, Scenter, Sright);

% Add in markers
Scomb = add_in_markers(Scomb, radius);

% Plot
figure; set(gcf, 'Position', [30 30 1800 650]);
for j = 1:3
    subplot(2,3,j);
    imagesc(Scomb(j).coronal.image_marked)
    axis off
end

for j = 1:3
    subplot(2, 3, 3 + j)
    imagesc(imrotate(Scomb(j).horizontal.image_marked, -90))
    axis off
end

end

%% combine for plotting ease
function [Scomb] = consolidate(Sleft, Scenter, Sright)

% Combine for plotting ease
Scomb(1) = Sleft;
Scomb(2) = Scenter;
Scomb(3) = Sright;

end

%% add in markers for injection sites - 
function [S_w_markers] = add_in_markers(S, radius)

nsections = length(S);
S_w_markers = S;

% Combine coordinates into one array
% coronal_coords_comb = cat(2, arrayfun(@(a) a.coronal.left, S)', ...
%     arrayfun(@(a) a.coronal.top, S)', ones(nsections,1)*radius);
horizontal_coords_comb = cat(2, arrayfun(@(a) a.horizontal.left, S)', ...
    arrayfun(@(a) a.horizontal.top, S)', ones(nsections,1)*radius);

for j = 1:nsections
    for k = 1:nsections
            S_w_markers(j).coronal.image_marked = insertShape(S_w_markers(j).coronal.image,...
                'FilledCircle',[S(j).coronal.left, S(j).coronal.top, radius],...
                'Color', 'r', 'Opacity', 1);
            S_w_markers(j).horizontal.image_marked = insertShape(S_w_markers(j).horizontal.image,...
                'FilledCircle', horizontal_coords_comb,...
                'Color', 'r', 'Opacity', 1);

    end


end

end

